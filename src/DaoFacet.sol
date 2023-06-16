// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// dependencies
import { ReentrancyGuard } from "solidstate/security/reentrancy_guard/ReentrancyGuard.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { LibString } from "solady/utils/LibString.sol";

// constants, structs and errors
import { PROTOCOL_ROLE } from "src/interfaces/D4AConstants.sol";
import {
    DaoMetadataParam,
    Whitelist,
    Blacklist,
    DaoMintCapParam,
    DaoETHAndERC20SplitRatioParam
} from "src/interfaces/D4AStructs.sol";
import {
    D4A__OnlyAdminCanSpecifyDaoIndex,
    D4A__ProtocolPaused,
    D4A__DaoPaused,
    D4A__UriNotExist,
    D4A__UriAlreadyExist,
    D4A__InvalidMintableRounds,
    D4A__RoyaltyFeeInBpsOutOfRange,
    D4A__InsufficientEther,
    D4A__DaoAlreadyExist,
    D4A__StartRoundAlreadyPassed
} from "src/interfaces/D4AErrors.sol";

// storages
import { DaoStorage } from "src/storages/DaoStorage.sol";
import { RewardStorage } from "src/storages/RewardStorage.sol";
import { SettingsStorage } from "src/storages/SettingsStorage.sol";
import { ProtocolStorage } from "src/storages/ProtocolStorage.sol";

// interfaces
import { IDaoFacet } from "src/interfaces/IDaoFacet.sol";
import { IDrb } from "src/interfaces/IDrb.sol";
import { IRoyaltyTokenFactory } from "src/interfaces/IRoyaltyTokenFactory.sol";
import { INftCollectionFactory } from "src/interfaces/INftCollectionFactory.sol";
import { IDaoFeePoolFactory } from "src/interfaces/IDaoFeePoolFactory.sol";

// contracts
import { AllowList } from "src/AllowList.sol";

contract DaoFacet is IDaoFacet, ReentrancyGuard {
    address public immutable WETH;
    address public immutable D4A_SWAP_FACTORY;

    constructor(address weth, address d4aSwapFactory) payable {
        WETH = weth;
        D4A_SWAP_FACTORY = d4aSwapFactory;
    }

    function createDao(
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        uint32 daoMintCap,
        uint256 actionType
    )
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        if (actionType & (1 << 0) != 0) {
            if (!AllowList(address(this)).hasAnyRole(msg.sender, PROTOCOL_ROLE)) {
                revert D4A__OnlyAdminCanSpecifyDaoIndex();
            }
            _checkProtocolPauseStatus();
            _checkUriNotExist(daoMetadataParam.daoUri);
            if (daoMetadataParam.startDrb > IDrb(address(this)).currentRound()) revert D4A__StartRoundAlreadyPassed();
            if (daoMetadataParam.mintableRounds > settingsStorage.maxDaoMintableRounds) {
                revert D4A__InvalidMintableRounds();
            }
            uint96 royaltyFeeInBps;
            if (
                royaltyFeeInBps < settingsStorage.minRoyaltyFeeInBps
                    || royaltyFeeInBps > settingsStorage.maxRoyaltyFeeInBps
            ) revert D4A__RoyaltyFeeInBpsOutOfRange();
            // transfer ETH to protocol
            {
                uint256 createDaoFee = settingsStorage.createDaoFee;
                if (msg.value < createDaoFee) revert D4A__InsufficientEther();
                SafeTransferLib.safeTransferETH(settingsStorage.protocolFeePool, createDaoFee);
                uint256 dust = msg.value - createDaoFee;
                if (dust > 0) SafeTransferLib.safeTransferETH(msg.sender, dust);
            }

            daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
            DaoStorage.DaoInfo storage daoInfo = daoStorage.daoInfos[daoId];
            if (daoInfo.exist) revert D4A__DaoAlreadyExist(daoId); // TODO: Is this necessary?

            ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(daoMetadataParam.daoUri))] = true;

            // update DAO info
            uint256 daoIndex = daoMetadataParam.daoIndex;
            {
                daoInfo.daoMetadata.startDrb = daoMetadataParam.startDrb;
                daoInfo.daoMetadata.index = daoIndex;
                daoInfo.daoMetadata.daoUri = daoMetadataParam.daoUri;
                daoInfo.mintableRounds = daoMetadataParam.mintableRounds;
                daoInfo.owner = msg.sender;
                daoInfo.exist = true;
            }

            // create royalty token
            address royaltyToken;
            {
                royaltyToken = IRoyaltyTokenFactory(settingsStorage.royaltyTokenFactory).createRoyaltyToken(
                    daoIndex, settingsStorage.assetAdmin, address(this), address(this)
                );
                daoInfo.royaltyTokenInfo.token = royaltyToken;
                daoInfo.royaltyTokenInfo.hardCap = settingsStorage.maxRoyaltyTokenSupply;
            }

            // create NFT collection
            address nftCollection;
            string memory daoUri = daoMetadataParam.daoUri;
            {
                nftCollection = INftCollectionFactory(settingsStorage.nftCollectionFactory).createNftCollection(
                    daoIndex, daoUri, settingsStorage.assetAdmin, address(this), address(this)
                );
                daoInfo.nftCollectionInfo.token = nftCollection;
                daoInfo.nftCollectionInfo.floorPrice = daoMetadataParam.floorPrice;
            }

            // create DAO Fee Pool
            address daoFeePool;
            {
                daoFeePool = IDaoFeePoolFactory(settingsStorage.daoFeePoolFactory).createDaoFeePool(
                    daoIndex, settingsStorage.assetAdmin, address(this)
                );
                daoInfo.daoMetadata.daoFeePool = daoFeePool;
            }

            emit NewDao(daoId, daoUri, royaltyFeeInBps, daoFeePool, royaltyToken, nftCollection);
        } else {
            _createDao();
        }

        if (actionType & (1 << 1) != 0) {
            _setPermission();
        }

        if (actionType & (1 << 2) != 0) {
            _setDaoMintCap(daoId, daoMintCap);
        }

        if (actionType & (1 << 3) != 0) {
            _createPair(daoId);
        }

        if (actionType & (1 << 4) != 0) {
            DaoStorage.DaoInfo storage daoInfo = daoStorage.daoInfos[daoId];
            RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
            _setETHSplitRatio(
                daoInfo, splitRatioParam.daoFeePoolETHRatioInBps, splitRatioParam.daoFeePoolETHRatioInBpsFlatPrice
            );
            _setRewardSplitRatio(
                rewardInfo, splitRatioParam.canvasCreatorERC20RatioInBps, splitRatioParam.nftMinterERC20RatioInBps
            );
        }
    }

    function _createDao() internal { }

    function _setPermission() internal { }

    function _setDaoMintCap(bytes32 daoId, uint32 daoMintCap) internal {
        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        daoStorage.daoInfos[daoId].nftCollectionInfo.mintCap = daoMintCap;
    }

    function _createPair(bytes32 daoId) internal {
        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        // d4aSwapFactory.createPair(daoStorage.daoInfos[daoId].collectionInfo.token, WETH);
    }

    function _setETHSplitRatio(
        DaoStorage.DaoInfo storage daoInfo,
        uint256 daoFeePoolETHRatioInBps,
        uint256 daoFeePoolETHRatioInBpsFlatPrice
    )
        internal
    {
        daoInfo.daoFeePoolETHRatioInBps = daoFeePoolETHRatioInBps;
        daoInfo.daoFeePoolETHRatioInBpsFlatPrice = daoFeePoolETHRatioInBpsFlatPrice;
    }

    function _setRewardSplitRatio(
        RewardStorage.RewardInfo storage rewardInfo,
        uint256 canvasCreatorERC20RatioInBps,
        uint256 nftMinterERC20RatioInBps
    )
        internal
    {
        rewardInfo.canvasCreatorERC20RatioInBps = canvasCreatorERC20RatioInBps;
        rewardInfo.nftMinterERC20RatioInBps = nftMinterERC20RatioInBps;
    }

    function _checkProtocolPauseStatus() internal view {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        if (settingsStorage.isProtocolPaused) {
            revert D4A__ProtocolPaused();
        }
    }

    function _checkPauseStatus(bytes32 daoId) internal view {
        DaoStorage.Layout storage daoStorage = DaoStorage.layout();
        if (daoStorage.daoInfos[daoId].isPaused) {
            revert D4A__DaoPaused(daoId);
        }
    }

    function _uriExist(string calldata daoUri) internal view returns (bool) {
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        return protocolStorage.uriExists[keccak256(abi.encodePacked(daoUri))];
    }

    function _checkUriExist(string calldata uri) internal view {
        if (!_uriExist(uri)) {
            revert D4A__UriNotExist(uri);
        }
    }

    function _checkUriNotExist(string calldata uri) internal view {
        if (_uriExist(uri)) {
            revert D4A__UriAlreadyExist(uri);
        }
    }
}

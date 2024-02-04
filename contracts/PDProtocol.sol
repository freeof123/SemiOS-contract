// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// external deps
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Initializable } from "@solidstate/contracts/security/initializable/Initializable.sol";
import { ReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { LibString } from "solady/utils/LibString.sol";
import { Multicallable } from "solady/utils/Multicallable.sol";

// D4A constants, structs, enums && errors
import { BASIS_POINT, SIGNER_ROLE, BASIC_DAO_RESERVE_NFT_NUMBER } from "contracts/interface/D4AConstants.sol";
import {
    DaoMintInfo,
    UserMintInfo,
    MintNftInfo,
    Whitelist,
    NftMinterCapInfo,
    UpdateRewardParam,
    MintNFTParam,
    CreateCanvasAndMintNFTParam,
    NftIdentifier
} from "contracts/interface/D4AStructs.sol";
import { DaoTag } from "contracts/interface/D4AEnums.sol";
import "contracts/interface/D4AErrors.sol";

// interfaces
import { IPriceTemplate } from "./interface/IPriceTemplate.sol";
import { IRewardTemplate } from "./interface/IRewardTemplate.sol";
import { IPermissionControl } from "./interface/IPermissionControl.sol";
import { ID4AProtocolReadable } from "./interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "./interface/IPDProtocolReadable.sol";
import { IPDProtocol } from "./interface/IPDProtocol.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";
import { IPDLock } from "./interface/IPDLock.sol";

// D4A storages && contracts
import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { SettingsStorage } from "./storages/SettingsStorage.sol";
import { GrantStorage } from "contracts/storages/GrantStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { RoundStorage } from "contracts/storages/RoundStorage.sol";
import { OwnerStorage } from "contracts/storages/OwnerStorage.sol";

import { D4AERC20 } from "./D4AERC20.sol";
import { D4AERC721 } from "./D4AERC721.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";
import { D4AVestingWallet } from "contracts/feepool/D4AVestingWallet.sol";
import { ProtocolChecker } from "contracts/ProtocolChecker.sol";

import { IRewardTemplate } from "./interface/IRewardTemplate.sol";
// import { CreateCanvasAndMintNFTCanvasParam } from "contracts/PDProtocolCanvas.sol";

// import "forge-std/Test.sol";

contract PDProtocol is IPDProtocol, ProtocolChecker, Initializable, ReentrancyGuard, Multicallable, EIP712 {
    using LibString for string;

    bytes32 internal constant _MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    function initialize() public reinitializer(2) {
        uint256 reservedDaoAmount = SettingsStorage.layout().reservedDaoAmount;
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.lastestDaoIndexes[uint8(DaoTag.D4A_DAO)] = reservedDaoAmount;
        protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)] = reservedDaoAmount;
    }

    function mintNFT(CreateCanvasAndMintNFTParam calldata vars) external payable nonReentrant returns (uint256) {
        _createCanvas(vars.daoId, vars.canvasId, vars.canvasUri, vars.canvasCreator, vars.canvasProof);
        MintNFTParam memory mintNFTAndTransferParam = MintNFTParam({
            daoId: vars.daoId,
            canvasId: vars.canvasId,
            tokenUri: vars.tokenUri,
            proof: vars.proof,
            flatPrice: vars.flatPrice,
            nftSignature: vars.nftSignature,
            nftOwner: vars.nftOwner,
            erc20Signature: vars.erc20Signature,
            deadline: vars.deadline,
            nftIdentifier: vars.nftIdentifier
        });
        return _mintNFTAndTransfer(mintNFTAndTransferParam);
    }

    function _createCanvas(
        bytes32 daoId,
        bytes32 canvasId,
        string memory canvasUri,
        address canvasCreator,
        bytes32[] calldata proof
    )
        internal
    {
        mapping(bytes32 => CanvasStorage.CanvasInfo) storage canvasInfos = CanvasStorage.layout().canvasInfos;
        if (canvasInfos[canvasId].canvasExist) return;

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.permissionControl.isCanvasCreatorBlacklisted(daoId, canvasCreator)) revert Blacklisted();
        if (!l.permissionControl.inCanvasCreatorWhitelist(daoId, canvasCreator, proof)) {
            revert NotInWhitelist();
        }
        ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(canvasUri))] = true;

        uint256 canvasIndex = DaoStorage.layout().daoInfos[daoId].canvases.length;

        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        {
            CanvasStorage.CanvasInfo storage canvasInfo = canvasInfos[canvasId];
            canvasInfo.daoId = daoId;
            canvasInfo.canvasUri = canvasUri;
            canvasInfo.index = canvasIndex + 1;
            settingsStorage.ownerProxy.initOwnerOf(canvasId, canvasCreator);
            canvasInfo.canvasExist = true;
        }
        emit NewCanvasForMint(daoId, canvasId, canvasUri);
        DaoStorage.layout().daoInfos[daoId].canvases.push(canvasId);
    }

    // function mintNFT(
    //     bytes32 daoId,
    //     bytes32 canvasId,
    //     string calldata tokenUri,
    //     bytes32[] calldata proof,
    //     uint256 flatPrice,
    //     bytes calldata nftSignature,
    //     bytes calldata erc20Signature,
    //     uint256 deadline
    // )
    //     external
    //     payable
    //     nonReentrant
    //     returns (uint256)
    // {
    //     MintNFTAndTransferParam memory vars = MintNFTAndTransferParam({
    //         daoId: daoId,
    //         canvasId: canvasId,
    //         tokenUri: tokenUri,
    //         proof: proof,
    //         flatPrice: flatPrice,
    //         nftSignature: nftSignature,
    //         to: msg.sender,
    //         erc20Signature: erc20Signature,
    //         deadline: deadline
    //     });
    //     return _mintNFTAndTransfer(vars);
    // }

    function updateTopUpAccount(bytes32 daoId, NftIdentifier memory nft) external returns (uint256, uint256) {
        return _usingTopUpAccount(daoId, nft);
    }

    function _usingTopUpAccount(bytes32 daoId, NftIdentifier memory nft) internal returns (uint256, uint256) {
        PoolStorage.PoolInfo storage poolInfo =
            PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[daoId].daoFeePool];

        bytes32[] memory investedTopUpDaos = poolInfo.nftInvestedTopUpDaos[_nftHash(nft)];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        for (uint256 i; i < investedTopUpDaos.length;) {
            (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
                abi.encodeCall(
                    IRewardTemplate.claimNftTopUpBalance,
                    (
                        investedTopUpDaos[i],
                        _nftHash(nft),
                        IPDRound(address(this)).getDaoCurrentRound(investedTopUpDaos[i]),
                        daoInfo.token
                    )
                )
            );
            require(succ, "delegate call failed");
            (uint256 minterERC20Reward, uint256 minterETHReward) = abi.decode(data, (uint256, uint256));

            emit PDClaimNftTopUpBalance(daoId, daoInfo.token, nft, minterERC20Reward, minterETHReward);
            unchecked {
                ++i;
            }
        }
        return (poolInfo.topUpNftERC20[_nftHash(nft)], poolInfo.topUpNftETH[_nftHash(nft)]);
    }

    //todo
    // function mintNFT(MintNFTParam memory vars) external payable nonReentrant returns (uint256 tokenId) {
    //     return _mintNFTAndTransfer(vars);
    // }

    function _mintNFTAndTransfer(MintNFTParam memory vars) internal returns (uint256 tokenId) {
        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[vars.daoId];
        if (DaoStorage.layout().daoInfos[vars.daoId].daoTag == DaoTag.BASIC_DAO && !basicDaoInfo.unifiedPriceModeOff) {
            if (vars.flatPrice != ID4AProtocolReadable(address(this)).getDaoUnifiedPrice(vars.daoId)) {
                revert NotBasicDaoNftFlatPrice();
            }
        } else {
            _verifySignature(vars.daoId, vars.canvasId, vars.tokenUri, vars.flatPrice, vars.nftSignature);
        }
        {
            uint256 currentRound = IPDRound(address(this)).getDaoCurrentRound(vars.daoId);
            _checkMintEligibility(vars.daoId, msg.sender, vars.proof, currentRound, 1);
            DaoStorage.layout().daoInfos[vars.daoId].roundMint[currentRound] += 1;
        }
        DaoStorage.layout().daoInfos[vars.daoId].daoMintInfo.userMintInfos[msg.sender].minted += 1;
        tokenId = _mintNft(
            vars.daoId,
            vars.canvasId,
            vars.tokenUri,
            vars.flatPrice,
            vars.nftOwner,
            vars.erc20Signature,
            vars.deadline,
            vars.nftIdentifier
        );
    }

    function claimDaoNftOwnerReward(bytes32 daoId)
        public
        nonReentrant
        returns (uint256 daoNftOwnerERC20Reward, uint256 daoNftOwnerETHReward)
    {
        _checkPauseStatus();
        _checkPauseStatus(daoId);
        _checkDaoExist(daoId);
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        OwnerStorage.DaoOwnerInfo storage ownerInfo = OwnerStorage.layout().daoOwnerInfos[daoId];
        address daoNftOwner =
            IERC721Upgradeable(ownerInfo.daoRewardOwner.erc721Address).ownerOf(ownerInfo.daoRewardOwner.tokenId);
        (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimDaoNftOwnerReward.selector,
                daoId,
                l.protocolFeePool,
                daoNftOwner,
                IPDRound(address(this)).getDaoCurrentRound(daoId),
                daoInfo.token
            )
        );
        require(succ);
        (, daoNftOwnerERC20Reward,, daoNftOwnerETHReward) = abi.decode(data, (uint256, uint256, uint256, uint256));

        emit PDClaimDaoCreatorReward(daoId, daoInfo.token, daoNftOwnerERC20Reward, daoNftOwnerETHReward);
    }

    function claimCanvasReward(bytes32 canvasId)
        public
        nonReentrant
        returns (uint256 canvasERC20Reward, uint256 canvasETHReward)
    {
        _checkPauseStatus();
        _checkPauseStatus(canvasId);
        _checkCanvasExist(canvasId);
        bytes32 daoId = CanvasStorage.layout().canvasInfos[canvasId].daoId;
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        address canvasCreator = l.ownerProxy.ownerOf(canvasId);
        (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimCanvasCreatorReward.selector,
                daoId,
                canvasId,
                canvasCreator,
                IPDRound(address(this)).getDaoCurrentRound(daoId),
                daoInfo.token
            )
        );
        require(succ);
        (canvasERC20Reward, canvasETHReward) = abi.decode(data, (uint256, uint256));

        emit PDClaimCanvasReward(daoId, canvasId, daoInfo.token, canvasERC20Reward, canvasETHReward);
    }

    function claimNftMinterReward(
        bytes32 daoId,
        address minter
    )
        public
        nonReentrant
        returns (uint256 minterERC20Reward, uint256 minterETHReward)
    {
        _checkPauseStatus();
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        (bool succ, bytes memory data) = l.rewardTemplates[uint8(daoInfo.rewardTemplateType)].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimNftMinterReward.selector,
                daoId,
                minter,
                IPDRound(address(this)).getDaoCurrentRound(daoId),
                daoInfo.token
            )
        );
        require(succ);
        (minterERC20Reward, minterETHReward) = abi.decode(data, (uint256, uint256));

        emit PDClaimNftMinterReward(daoId, daoInfo.token, minterERC20Reward, minterETHReward);

        // else {
        //     emit PDClaimNftMinterRewardTopUp(daoId, daoInfo.token, minterERC20Reward, minterETHReward);
        // }
    }

    struct ExchangeERC20ToETHLocalVars {
        uint256 tokenCirculation;
        uint256 tokenAmount;
    }

    function exchangeERC20ToETH(bytes32 daoId, uint256 tokenAmount, address to) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken) return 0;
        address token = daoInfo.token;
        address daoFeePool = daoInfo.daoFeePool;

        D4AERC20(token).burn(msg.sender, tokenAmount);
        D4AERC20(token).mint(daoFeePool, tokenAmount);

        ExchangeERC20ToETHLocalVars memory vars;

        vars.tokenCirculation = IPDProtocolReadable(address(this)).getDaoCirculateTokenAmount(daoId) + tokenAmount
            - D4AERC20(token).balanceOf(daoFeePool);
        if (vars.tokenCirculation == 0) return 0;

        GrantStorage.Layout storage grantStorage = GrantStorage.layout();
        D4AVestingWallet vestingWallet = D4AVestingWallet(payable(grantStorage.vestingWallets[daoId]));
        vars.tokenAmount = tokenAmount;
        if (address(vestingWallet) != address(0)) {
            vestingWallet.release();
            address[] memory allowedTokenList = grantStorage.allowedTokenList;
            for (uint256 i; i < allowedTokenList.length;) {
                vestingWallet.release(allowedTokenList[i]);
                uint256 grantTokenAmount =
                    (vars.tokenAmount * IERC20(allowedTokenList[i]).balanceOf(daoFeePool)) / vars.tokenCirculation;
                if (grantTokenAmount > 0) {
                    emit D4AExchangeERC20ToERC20(
                        daoId, msg.sender, to, allowedTokenList[i], vars.tokenAmount, grantTokenAmount
                    );
                    D4AFeePool(payable(daoFeePool)).transfer(allowedTokenList[i], payable(to), grantTokenAmount);
                }
                unchecked {
                    ++i;
                }
            }
        }
        uint256 availableETH = daoFeePool.balance;
        uint256 ethAmount = (tokenAmount * availableETH) / vars.tokenCirculation;

        if (ethAmount != 0) D4AFeePool(payable(daoFeePool)).transfer(address(0x0), payable(to), ethAmount);

        emit D4AExchangeERC20ToETH(daoId, msg.sender, to, tokenAmount, ethAmount);

        return ethAmount;
    }

    function _checkCanvasExist(bytes32 canvasId) internal view {
        if (!CanvasStorage.layout().canvasInfos[canvasId].canvasExist) revert CanvasNotExist();
    }

    function _checkMintEligibility(
        bytes32 daoId,
        address account,
        bytes32[] memory proof,
        uint256 currentRound,
        uint256 amount
    )
        internal
        view
    {
        if (block.number < DaoStorage.layout().daoInfos[daoId].startBlock) {
            revert DaoNotStarted();
        }
        if (
            DaoStorage.layout().daoInfos[daoId].roundMint[currentRound] + amount
                > BasicDaoStorage.layout().basicDaoInfos[daoId].roundMintCap
                && BasicDaoStorage.layout().basicDaoInfos[daoId].roundMintCap != 0
        ) revert ExceedDailyMintCap();
        {
            if (!_ableToMint(daoId, account, proof, amount)) revert ExceedMinterMaxMintAmount();
        }
    }

    function _ableToMint(
        bytes32 daoId,
        address account,
        bytes32[] memory proof,
        uint256 amount
    )
        internal
        view
        returns (bool)
    {
        /*
        Checking priority
        1. blacklist
        2. if whitelist on, designated user mint cap
        3. NFT holder pass mint cap
        4. dao mint cap
        */
        IPermissionControl permissionControl = SettingsStorage.layout().permissionControl;

        if (permissionControl.isMinterBlacklisted(daoId, account)) {
            revert Blacklisted();
        }
        DaoMintInfo storage daoMintInfo = DaoStorage.layout().daoInfos[daoId].daoMintInfo;
        uint32 daoMintCap = daoMintInfo.daoMintCap;
        UserMintInfo memory userMintInfo = daoMintInfo.userMintInfos[account];

        Whitelist memory whitelist = permissionControl.getWhitelist(daoId);

        bool isWhitelistOff = whitelist.minterMerkleRoot == bytes32(0) && whitelist.minterNFTHolderPasses.length == 0
            && DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo.length == 0;

        uint256 expectedMinted = userMintInfo.minted + amount;

        if (isWhitelistOff) {
            return daoMintCap == 0 ? true : expectedMinted <= daoMintCap;
        }

        if (permissionControl.inMinterWhitelist(daoId, account, proof)) {
            //revert NotInWhitelist();
            if (userMintInfo.mintCap != 0) return expectedMinted <= userMintInfo.mintCap;
            return true;
        }
        return _ableToMintFor721(daoId, expectedMinted, account);
    }

    function _ableToMintFor721(bytes32 daoId, uint256 expectedMinted, address account) internal view returns (bool) {
        IPermissionControl permissionControl = SettingsStorage.layout().permissionControl;
        NftMinterCapInfo[] memory nftMinterCapInfo = DaoStorage.layout().daoInfos[daoId].nftMinterCapInfo;
        uint256 length = nftMinterCapInfo.length;
        uint256 minMintCap = 1_000_000;
        bool hasMinterCapNft = false;
        for (uint256 i; i < length;) {
            if (IERC721Upgradeable(nftMinterCapInfo[i].nftAddress).balanceOf(account) > 0) {
                hasMinterCapNft = true;
                if (nftMinterCapInfo[i].nftMintCap < minMintCap) {
                    minMintCap = nftMinterCapInfo[i].nftMintCap;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (hasMinterCapNft) {
            return expectedMinted <= minMintCap;
        }
        Whitelist memory whitelist = permissionControl.getWhitelist(daoId);
        return permissionControl.inMinterNFTHolderPasses(whitelist, account);
    }

    function _verifySignature(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 nftFlatPrice,
        bytes memory signature
    )
        internal
        view
    {
        // check for special token URIs first
        if (_isSpecialTokenUri(daoId, tokenUri)) return;

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        bytes32 digest =
            _hashTypedData(keccak256(abi.encode(_MINTNFT_TYPEHASH, canvasId, keccak256(bytes(tokenUri)), nftFlatPrice)));
        address signer = ECDSAUpgradeable.recover(digest, signature);
        if (
            !IAccessControlUpgradeable(address(this)).hasRole(SIGNER_ROLE, signer)
                && signer != l.ownerProxy.ownerOf(canvasId)
        ) revert InvalidSignature();
    }

    function _isSpecialTokenUri(bytes32 daoId, string memory tokenUri) internal view returns (bool) {
        if (!BasicDaoStorage.layout().basicDaoInfos[daoId].needMintableWork) return false;
        string memory specialTokenUriPrefix = BasicDaoStorage.layout().specialTokenUriPrefix;
        string memory daoIndex = LibString.toString(DaoStorage.layout().daoInfos[daoId].daoIndex);
        if (!tokenUri.startsWith(specialTokenUriPrefix.concat(daoIndex).concat("-"))) return false;
        // strip prefix, daoIndex at the start and `.json` at the end
        string memory tokenIndexString =
            tokenUri.slice(bytes(specialTokenUriPrefix).length + bytes(daoIndex).length + 1, bytes(tokenUri).length - 5);
        // try parse tokenIndex from string to uint256;
        uint256 tokenIndex;
        for (uint256 i; i < bytes(tokenIndexString).length; ++i) {
            if (bytes(tokenIndexString)[i] < "0" || bytes(tokenIndexString)[i] > "9") return false;
            tokenIndex = tokenIndex * 10 + (uint8(bytes(tokenIndexString)[i]) - 48);
        }
        if (tokenIndex == 0 || tokenIndex > ID4AProtocolReadable(address(this)).getDaoReserveNftNumber(daoId)) {
            return false;
        }
        return true;
    }

    function _fetchRightTokenUri(bytes32 daoId, uint256 tokenId) internal view returns (string memory) {
        string memory daoIndex = LibString.toString(DaoStorage.layout().daoInfos[daoId].daoIndex);
        return BasicDaoStorage.layout().specialTokenUriPrefix.concat(daoIndex).concat("-").concat(
            LibString.toString(tokenId)
        ).concat(".json");
    }

    function _mintNft(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        address to,
        bytes memory erc20Signature,
        uint256 deadline,
        NftIdentifier memory nft
    )
        internal
        returns (uint256 tokenId)
    {
        // for special token uri, if two same speical token uris are passes in at the same time, should fetch right
        // token uri first, then check for uri non-existence
        {
            BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
            if (_isSpecialTokenUri(daoId, tokenUri)) {
                ++basicDaoInfo.tokenId;
                if (canvasId != basicDaoInfo.canvasIdOfSpecialNft) {
                    revert NotCanvasIdOfSpecialTokenUri();
                }
                if (flatPrice != PriceStorage.layout().daoFloorPrices[daoId] && basicDaoInfo.unifiedPriceModeOff) {
                    revert NotBasicDaoFloorPrice();
                }
                tokenUri = _fetchRightTokenUri(daoId, basicDaoInfo.tokenId);
                tokenId = basicDaoInfo.tokenId;
            }
        }

        {
            _checkPauseStatus();
            _checkPauseStatus(canvasId);
            _checkCanvasExist(canvasId);
            _checkUriNotExist(tokenUri);
            if (CanvasStorage.layout().canvasInfos[canvasId].daoId != daoId) revert NotCanvasIdOfDao();
        }

        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.nftTotalSupply >= daoInfo.nftMaxSupply) revert NftExceedMaxAmount();

        ProtocolStorage.layout().uriExists[keccak256(abi.encodePacked(tokenUri))] = true;

        // mint
        tokenId = D4AERC721(daoInfo.nft).mintItem(to, tokenUri, tokenId, false);
        {
            CanvasStorage.CanvasInfo storage canvasInfo = CanvasStorage.layout().canvasInfos[canvasId];
            daoInfo.nftTotalSupply++;
            canvasInfo.tokenIds.push(tokenId);
            ProtocolStorage.layout().nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenId))] = canvasId;
        }

        // get next mint price
        uint256 price;
        {
            uint256 currentRound = IPDRound(address(this)).getDaoCurrentRound(daoId);
            uint256 nftPriceFactor = daoInfo.nftPriceFactor;
            price = _getCanvasNextPrice(daoId, canvasId, flatPrice, 1, currentRound, nftPriceFactor);
            _updatePrice(currentRound, daoId, canvasId, price, flatPrice, nftPriceFactor);

            NftIdentifier memory nftIdentifier = BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode
                && nft.erc721Address == address(0) ? NftIdentifier({ erc721Address: daoInfo.nft, tokenId: tokenId }) : nft;
            // split fee
            _calculateAndSplitFeeAndUpdateReward(
                daoId, canvasId, price, flatPrice, currentRound, erc20Signature, deadline, nftIdentifier
            );
            emit D4AMintNFT(daoId, canvasId, tokenId, tokenUri, price, nftIdentifier);
        }
    }

    struct SplitFeeLocalVars {
        bytes32 daoId;
        uint256 price;
        address protocolFeePool;
        address daoRedeemPool;
        address daoAssetPool;
        address canvasOwner;
        uint256 redeemPoolFee;
        uint256 assetPoolFee;
        bytes erc20Signature;
        uint256 deadline;
        bytes32 nftHash;
        NftIdentifier nft;
    }

    function _calculateAndSplitFeeAndUpdateReward(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 price,
        uint256 flatPrice,
        uint256 currentRound,
        bytes memory erc20Signature,
        uint256 deadline,
        NftIdentifier memory nft
    )
        internal
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        uint256 daoFee;

        if (BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode) {
            RewardStorage.layout().rewardInfos[daoId].nftTopUpInvestorPendingETH[currentRound][_nftHash(nft)] += price;
            bool exist;
            bytes32[] storage investedDaos =
                PoolStorage.layout().poolInfos[daoInfo.daoFeePool].nftInvestedTopUpDaos[_nftHash(nft)];
            for (uint256 i; i < investedDaos.length;) {
                if (investedDaos[i] == daoId) {
                    exist = true;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            if (!exist) investedDaos.push(daoId);
            //split fee
            if (msg.value < price) revert NotEnoughEther();
            uint256 dust = msg.value - price;
            if (dust > 0) SafeTransferLib.safeTransferETH(msg.sender, dust);
            //因为topUp模式下daoAssetPool不流入资产，以price作为权重
            daoFee = price;
            emit MintFeePendingToNftTopUpAccount(daoId, nft, price);
        } else {
            if (nft.erc721Address != address(0) && msg.sender != IERC721(nft.erc721Address).ownerOf(nft.tokenId)) {
                revert NotNftOwner();
            }
            SplitFeeLocalVars memory vars;
            vars.daoId = daoId;
            vars.price = price;
            vars.protocolFeePool = l.protocolFeePool;
            vars.daoRedeemPool = daoInfo.daoFeePool;
            vars.daoAssetPool = BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool;
            vars.canvasOwner = l.ownerProxy.ownerOf(canvasId);
            vars.deadline = deadline;
            vars.erc20Signature = erc20Signature;
            vars.nftHash = _nftHash(nft);
            vars.nft = nft;
            vars.redeemPoolFee = (
                (
                    flatPrice == 0
                        ? IPDProtocolReadable(address(this)).getRedeemPoolMintFeeRatio(daoId)
                        : IPDProtocolReadable(address(this)).getRedeemPoolMintFeeRatioFiatPrice(daoId)
                ) * price
            ) / BASIS_POINT;
            vars.assetPoolFee = (
                (
                    flatPrice == 0
                        ? IPDProtocolReadable(address(this)).getAssetPoolMintFeeRatio(daoId)
                        : IPDProtocolReadable(address(this)).getAssetPoolMintFeeRatioFiatPrice(daoId)
                ) * price
            ) / BASIS_POINT;
            daoFee =
                BasicDaoStorage.layout().basicDaoInfos[daoId].erc20PaymentMode ? _splitFeeERC20(vars) : _splitFee(vars);
        }

        _updateReward(
            daoId,
            canvasId,
            //如果mint的价格为0，为了达到以数量为权重分配reward的目的，统一传1 ether作为daoFeeAmount
            price == 0 ? 1 ether : daoFee,
            price == 0,
            _nftHash(nft)
        );
        if (!BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode && daoFee > 0) {
            if (!BasicDaoStorage.layout().basicDaoInfos[daoId].erc20PaymentMode) {
                SafeTransferLib.safeTransferETH(BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool, daoFee);
            } else {
                SafeTransferLib.safeTransfer(
                    daoInfo.token, BasicDaoStorage.layout().basicDaoInfos[daoId].daoAssetPool, daoFee
                );
            }
        }
    }

    function _updatePrice(
        uint256 currentRound,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 price,
        uint256 flatPrice,
        uint256 nftPriceMultiplyFactor
    )
        internal
    {
        if (flatPrice == 0) {
            (bool succ,) = SettingsStorage.layout().priceTemplates[uint8(
                DaoStorage.layout().daoInfos[daoId].priceTemplateType
            )].delegatecall(
                abi.encodeWithSelector(
                    IPriceTemplate.updateCanvasPrice.selector,
                    daoId,
                    canvasId,
                    currentRound,
                    price,
                    nftPriceMultiplyFactor
                )
            );
            require(succ);
        }
    }

    struct BatchMintLocalVars {
        uint256 length;
        uint256 currentRound;
        uint256 nftPriceFactor;
        uint256 daoTotalShare;
        uint256 totalPrice;
    }

    function _getCanvasNextPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 flatPrice,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceFactor
    )
        internal
        view
        returns (uint256 price)
    {
        PriceStorage.Layout storage priceStorage = PriceStorage.layout();
        uint256 daoFloorPrice = priceStorage.daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = priceStorage.daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = priceStorage.canvasLastMintInfos[canvasId];
        //对于D4A的DAO,还是按原来逻辑
        if (
            flatPrice == 0
                && (
                    BasicDaoStorage.layout().basicDaoInfos[daoId].unifiedPriceModeOff
                        || DaoStorage.layout().daoInfos[daoId].daoTag == DaoTag.D4A_DAO
                )
        ) {
            price = IPriceTemplate(
                SettingsStorage.layout().priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)]
            ).getCanvasNextPrice(startRound, currentRound, priceFactor, daoFloorPrice, maxPrice, mintInfo);
        } else {
            price = flatPrice;
        }
    }

    function _updateReward(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 daoFeeAmount,
        bool zeroPrice,
        bytes32 nftHash
    )
        internal
    {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        //_checkUriNotExistSettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ,) = SettingsStorage.layout().rewardTemplates[uint8(
            DaoStorage.layout().daoInfos[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.updateReward.selector,
                UpdateRewardParam(
                    daoId,
                    canvasId,
                    daoInfo.token,
                    daoInfo.startBlock,
                    IPDRound(address(this)).getDaoCurrentRound(daoId),
                    daoInfo.mintableRound,
                    daoFeeAmount,
                    daoInfo.daoFeePool,
                    zeroPrice,
                    BasicDaoStorage.layout().basicDaoInfos[daoId].topUpMode,
                    nftHash
                )
            )
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _splitFee(SplitFeeLocalVars memory vars) internal returns (uint256) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 topUpETHQuota;
        if (vars.nft.erc721Address != address(0) && !IPDLock(address(this)).checkTopUpNftLockedStatus(vars.nft)) {
            (, topUpETHQuota) = _usingTopUpAccount(vars.daoId, vars.nft);
        }
        uint256 protocolFee = (vars.price * l.protocolMintFeeRatioInBps) / BASIS_POINT;
        uint256 canvasCreatorFee = vars.price - vars.redeemPoolFee - protocolFee - vars.assetPoolFee;
        uint256 dust;
        if (msg.value + topUpETHQuota < vars.price) revert NotEnoughEther();

        if (protocolFee > 0) SafeTransferLib.safeTransferETH(vars.protocolFeePool, protocolFee);
        if (vars.redeemPoolFee > 0) SafeTransferLib.safeTransferETH(vars.daoRedeemPool, vars.redeemPoolFee);
        //should split after update reward
        //if (vars.assetPoolFee > 0) SafeTransferLib.safeTransferETH(vars.daoAssetPool, vars.assetPoolFee);
        if (canvasCreatorFee > 0) SafeTransferLib.safeTransferETH(vars.canvasOwner, canvasCreatorFee);
        uint256 topUpAmountETHToUse;

        //bytes32 _hash = _nftHash(vars.nft);

        if (topUpETHQuota < vars.price) {
            dust = msg.value + topUpETHQuota - vars.price;
            topUpAmountETHToUse = topUpETHQuota;
        } else {
            dust = msg.value;
            topUpAmountETHToUse = vars.price;
        }
        if (dust > 0) SafeTransferLib.safeTransferETH(msg.sender, dust);
        if (topUpETHQuota > 0) {
            PoolStorage.PoolInfo storage poolInfo =
                PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[vars.daoId].daoFeePool];
            uint256 topUpAmountERC20 = (topUpAmountETHToUse * poolInfo.topUpNftERC20[vars.nftHash]) / topUpETHQuota;
            poolInfo.topUpNftETH[vars.nftHash] -= topUpAmountETHToUse;
            poolInfo.topUpNftERC20[vars.nftHash] -= topUpAmountERC20;
            uint256 topUpAmountErc20ToTreasury = topUpAmountERC20
                * BasicDaoStorage.layout().basicDaoInfos[vars.daoId].topUpErc20ToTreasuryRatio / BASIS_POINT;
            SafeTransferLib.safeTransfer(
                DaoStorage.layout().daoInfos[vars.daoId].token,
                msg.sender,
                topUpAmountERC20 - topUpAmountErc20ToTreasury
            );
            SafeTransferLib.safeTransfer(
                DaoStorage.layout().daoInfos[vars.daoId].token, poolInfo.treasury, topUpAmountErc20ToTreasury
            );
            emit TopUpAmountUsed(
                vars.nft,
                vars.daoId,
                DaoStorage.layout().daoInfos[vars.daoId].daoFeePool,
                topUpAmountERC20,
                topUpAmountETHToUse
            );
            emit TopUpErc20ToTreasury(msg.sender, vars.daoId, poolInfo.treasury, topUpAmountErc20ToTreasury);
        }
        emit MintFeeSplitted(
            vars.daoId,
            vars.daoRedeemPool,
            vars.redeemPoolFee,
            vars.canvasOwner,
            canvasCreatorFee,
            vars.daoAssetPool,
            vars.assetPoolFee
        );
        return vars.assetPoolFee;
    }

    function _splitFeeERC20(SplitFeeLocalVars memory vars) internal returns (uint256) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 topUpERC20Quota;
        if (vars.nft.erc721Address != address(0) && !IPDLock(address(this)).checkTopUpNftLockedStatus(vars.nft)) {
            (topUpERC20Quota,) = _usingTopUpAccount(vars.daoId, vars.nft);
        }

        uint256 protocolFee = (vars.price * l.protocolMintFeeRatioInBps) / BASIS_POINT;
        uint256 canvasCreatorFee = vars.price - vars.redeemPoolFee - protocolFee - vars.assetPoolFee;
        address token = DaoStorage.layout().daoInfos[vars.daoId].token;
        //if (msg.value + topUpETHQuota < vars.price) revert NotEnoughEther();
        uint256 topUpAmountERC20ToUse;

        if (topUpERC20Quota < vars.price) {
            topUpAmountERC20ToUse = topUpERC20Quota;
            //deadline rather than erc20Signature
            if (vars.deadline != 0) {
                (uint8 v, bytes32 r, bytes32 s) = abi.decode(vars.erc20Signature, (uint8, bytes32, bytes32));
                IERC20Permit(token).permit(
                    msg.sender, address(this), vars.price - topUpERC20Quota, vars.deadline, v, r, s
                );
            }
            SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), vars.price - topUpERC20Quota);
        } else {
            topUpAmountERC20ToUse = vars.price;
        }
        if (protocolFee > 0) SafeTransferLib.safeTransfer(token, vars.protocolFeePool, protocolFee);
        if (vars.redeemPoolFee > 0) SafeTransferLib.safeTransfer(token, vars.daoRedeemPool, vars.redeemPoolFee);
        //should split after update reward
        //if (vars.assetPoolFee > 0) SafeTransferLib.safeTransferETH(vars.daoAssetPool, vars.assetPoolFee);
        if (canvasCreatorFee > 0) SafeTransferLib.safeTransfer(token, vars.canvasOwner, canvasCreatorFee);

        if (topUpERC20Quota > 0) {
            PoolStorage.PoolInfo storage poolInfo =
                PoolStorage.layout().poolInfos[DaoStorage.layout().daoInfos[vars.daoId].daoFeePool];
            uint256 topUpAmountETH = (topUpAmountERC20ToUse * poolInfo.topUpNftETH[vars.nftHash]) / topUpERC20Quota;
            poolInfo.topUpNftETH[vars.nftHash] -= topUpAmountETH;
            poolInfo.topUpNftERC20[vars.nftHash] -= topUpAmountERC20ToUse;
            uint256 topUpAmountEthToRedeemPool = topUpAmountETH
                * BasicDaoStorage.layout().basicDaoInfos[vars.daoId].topUpEthToRedeemPoolRatio / BASIS_POINT;
            SafeTransferLib.safeTransferETH(msg.sender, topUpAmountETH - topUpAmountEthToRedeemPool);
            SafeTransferLib.safeTransferETH(vars.daoRedeemPool, topUpAmountEthToRedeemPool);
            emit TopUpAmountUsed(
                vars.nft,
                vars.daoId,
                DaoStorage.layout().daoInfos[vars.daoId].daoFeePool,
                topUpAmountERC20ToUse,
                topUpAmountETH
            );
            emit TopUpEthToRedeemPool(msg.sender, vars.daoId, vars.daoRedeemPool, topUpAmountEthToRedeemPool);
        }
        emit MintFeeSplitted(
            vars.daoId,
            vars.daoRedeemPool,
            vars.redeemPoolFee,
            vars.canvasOwner,
            canvasCreatorFee,
            vars.daoAssetPool,
            vars.assetPoolFee
        );
        return vars.assetPoolFee;
    }

    function _nftHash(NftIdentifier memory nft) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft.erc721Address, nft.tokenId));
    }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "ProtoDaoProtocol";
        version = "1";
    }
}

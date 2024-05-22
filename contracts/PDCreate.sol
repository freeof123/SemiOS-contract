// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// interfaces
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { DaoTag } from "contracts/interface/D4AEnums.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolSetter } from "contracts/interface/IPDProtocolSetter.sol";
import { ID4AChangeAdmin } from "./interface/ID4AChangeAdmin.sol";
import { BASIS_POINT, BASIC_DAO_RESERVE_NFT_NUMBER } from "contracts/interface/D4AConstants.sol";
import {
    CreateSemiDaoParam,
    DaoMetadataParam,
    Whitelist,
    Blacklist,
    DaoMintCapParam,
    SetMintCapAndPermissionParam,
    ContinuousDaoParam,
    NftMinterCapInfo,
    TemplateParam,
    BasicDaoParam,
    AllRatioParam,
    SetChildrenParam,
    NftMinterCapIdInfo
} from "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

// setting
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";

// storages
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { TreeStorage } from "contracts/storages/TreeStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RoundStorage } from "contracts/storages/RoundStorage.sol";
import { PoolStorage } from "contracts/storages/PoolStorage.sol";
import { ProtocolChecker } from "contracts/ProtocolChecker.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { LibString } from "solady/utils/LibString.sol";
import { D4AERC20 } from "./D4AERC20.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";

import "forge-std/Test.sol";

struct CreateProjectLocalVars {
    bytes32 existDaoId;
    bytes32 daoId;
    address daoFeePool;
    address daoAssetPool;
    address token;
    address nft;
    DaoMetadataParam daoMetadataParam;
    Whitelist whitelist;
    Blacklist blacklist;
    DaoMintCapParam daoMintCapParam;
    NftMinterCapInfo[] nftMinterCapInfo;
    NftMinterCapIdInfo[] nftMinterCapIdInfo;
    TemplateParam templateParam;
    BasicDaoParam basicDaoParam;
    AllRatioParam allRatioParam;
    uint256 actionType;
    bool needMintableWork;
    uint256 dailyMintCap;
    uint8 version;
    bool topUpMode;
}

struct CreateAncestorDaoParam {
    bytes32 daoId;
    uint256 daoIndex;
    string daoName;
    address daoToken;
    address inputToken;
}

struct CreateContinuousDaoParam {
    bytes32 daoId;
    address tokenAddress;
    address feePoolAddress;
    address inputToken;
}

contract PDCreate is IPDCreate, ProtocolChecker, ReentrancyGuard {
    address public immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    function createDao(CreateSemiDaoParam calldata createDaoParam)
        public
        payable
        override
        nonReentrant
        returns (bytes32 daoId)
    {
        CreateProjectLocalVars memory vars;
        vars.existDaoId = createDaoParam.existDaoId;
        vars.daoMetadataParam = createDaoParam.daoMetadataParam;
        vars.whitelist = createDaoParam.whitelist;
        vars.blacklist = createDaoParam.blacklist;
        vars.daoMintCapParam = createDaoParam.daoMintCapParam;
        vars.nftMinterCapInfo = createDaoParam.nftMinterCapInfo;
        vars.nftMinterCapIdInfo = createDaoParam.nftMinterCapIdInfo;
        vars.templateParam = createDaoParam.templateParam;
        vars.basicDaoParam = createDaoParam.basicDaoParam;
        vars.actionType = createDaoParam.actionType;
        vars.needMintableWork = createDaoParam.continuousDaoParam.needMintableWork;
        vars.dailyMintCap = createDaoParam.continuousDaoParam.dailyMintCap;
        vars.allRatioParam = createDaoParam.allRatioParam;

        if (createDaoParam.daoMetadataParam.floorPrice == 0) revert CannotUseZeroFloorPrice();

        if (
            createDaoParam.continuousDaoParam.reserveNftNumber == 0
                && createDaoParam.continuousDaoParam.needMintableWork
        ) {
            revert ZeroNftReserveNumber(); //要么不开，开了就不能传0
        }

        if (createDaoParam.continuousDaoParam.outputPaymentMode && createDaoParam.continuousDaoParam.topUpMode) {
            revert PaymentModeAndTopUpModeCannotBeBothOn();
        }

        daoId = _createDao(
            createDaoParam.existDaoId,
            createDaoParam.daoMetadataParam,
            createDaoParam.basicDaoParam,
            createDaoParam.continuousDaoParam,
            createDaoParam.actionType
        );

        {
            vars.daoId = daoId;
            // Use the exist DaoFeePool and DaoToken
            vars.daoFeePool = ID4AProtocolReadable(address(this)).getDaoFeePool(vars.daoId);
            vars.daoAssetPool = IPDProtocolReadable(address(this)).getDaoAssetPool(vars.daoId);
            vars.token = ID4AProtocolReadable(address(this)).getDaoToken(vars.daoId);
            vars.nft = ID4AProtocolReadable(address(this)).getDaoNft(vars.daoId); //var.nft here is the erc721 address
            vars.topUpMode = createDaoParam.continuousDaoParam.topUpMode;
        }

        emit CreateContinuousProjectParamEmitted(
            vars.existDaoId,
            vars.daoId,
            vars.dailyMintCap,
            vars.needMintableWork,
            createDaoParam.continuousDaoParam.unifiedPriceModeOff,
            createDaoParam.continuousDaoParam.unifiedPrice,
            createDaoParam.continuousDaoParam.reserveNftNumber,
            createDaoParam.continuousDaoParam.topUpMode,
            createDaoParam.continuousDaoParam.infiniteMode,
            createDaoParam.continuousDaoParam.outputPaymentMode,
            createDaoParam.continuousDaoParam.inputToken
        );
        _config(address(this), vars);

        //if (!continuousDaoParam.isAncestorDao) {
        IPDProtocolSetter(address(this)).setChildren(
            vars.daoId,
            SetChildrenParam(
                createDaoParam.continuousDaoParam.childrenDaoId,
                createDaoParam.continuousDaoParam.childrenDaoOutputRatios,
                createDaoParam.continuousDaoParam.childrenDaoInputRatios,
                createDaoParam.continuousDaoParam.redeemPoolInputRatio,
                createDaoParam.continuousDaoParam.treasuryOutputRatio,
                createDaoParam.continuousDaoParam.treasuryInputRatio,
                createDaoParam.continuousDaoParam.selfRewardOutputRatio,
                createDaoParam.continuousDaoParam.selfRewardInputRatio
            )
        );
        //}
        // return vars.daoId;
    }

    function _createDao(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        BasicDaoParam calldata basicDaoParam,
        ContinuousDaoParam calldata continuousDaoParam,
        uint256 actionType
    )
        internal
        returns (bytes32 daoId)
    {
        // here need to check daoid if exist // we checked it in this function

        super._checkPauseStatus();
        super._checkUriNotExist(daoMetadataParam.projectUri);
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

        if (daoMetadataParam.startBlock != 0 && daoMetadataParam.startBlock < block.number) {
            revert StartBlockAlreadyPassed();
        }
        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        {
            uint256 daoIndex;

            if (actionType & 0x1 != 0) {
                if (daoMetadataParam.projectIndex >= settingsStorage.reservedDaoAmount) revert DaoIndexTooLarge();
                if (((protocolStorage.d4aDaoIndexBitMap >> daoMetadataParam.projectIndex) & 1) != 0) {
                    revert DaoIndexAlreadyExist();
                }
                protocolStorage.d4aDaoIndexBitMap |= (1 << daoMetadataParam.projectIndex);
                daoIndex = daoMetadataParam.projectIndex;
            } else {
                daoIndex = protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];
                ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];
            }
            daoInfo.daoIndex = daoIndex;
        }
        // repeat part

        daoInfo.daoUri = daoMetadataParam.projectUri;

        settingsStorage.ownerProxy.initOwnerOf(daoId, msg.sender); //before: createprojectproxy, now :user

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        daoInfo.daoExist = true;

        CreateContinuousDaoParam memory createContinuousDaoParam;
        if (!continuousDaoParam.isAncestorDao) {
            if (!TreeStorage.layout().treeInfos[existDaoId].isAncestorDao) revert NotAncestorDao();
            createContinuousDaoParam.daoId = daoId;

            createContinuousDaoParam.tokenAddress = DaoStorage.layout().daoInfos[existDaoId].token;
            createContinuousDaoParam.feePoolAddress = DaoStorage.layout().daoInfos[existDaoId].daoFeePool;
            createContinuousDaoParam.inputToken = DaoStorage.layout().daoInfos[existDaoId].inputToken;
            _createContinuousProject(createContinuousDaoParam);
            TreeStorage.layout().treeInfos[daoId].ancestor = existDaoId;
            TreeStorage.layout().treeInfos[existDaoId].familyDaos.push(daoId);
            BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken =
                BasicDaoStorage.layout().basicDaoInfos[existDaoId].isThirdPartyToken;
        } else {
            _createProject(
                CreateAncestorDaoParam(
                    daoId,
                    daoInfo.daoIndex,
                    basicDaoParam.daoName,
                    continuousDaoParam.daoToken,
                    continuousDaoParam.inputToken
                )
            );
            TreeStorage.layout().treeInfos[daoId].isAncestorDao = true;
            TreeStorage.layout().treeInfos[daoId].ancestor = daoId;
            TreeStorage.layout().treeInfos[daoId].familyDaos.push(daoId);
        }
        _createDaoERC721(
            daoId,
            daoInfo.daoIndex,
            basicDaoParam.daoName,
            continuousDaoParam.needMintableWork,
            continuousDaoParam.reserveNftNumber,
            daoMetadataParam.projectUri,
            continuousDaoParam.ownershipUri
        );

        //common initializaitions
        {
            RoundStorage.RoundInfo storage roundInfo = RoundStorage.layout().roundInfos[daoId];
            if (daoMetadataParam.duration == 0) revert DurationIsZero();
            roundInfo.roundDuration = daoMetadataParam.duration;
            roundInfo.roundInLastModify = 1;

            daoInfo.startBlock = daoMetadataParam.startBlock == 0 ? block.number : daoMetadataParam.startBlock;
            roundInfo.blockInLastModify = daoInfo.startBlock;

            daoInfo.mintableRound = daoMetadataParam.mintableRounds;
            PriceStorage.layout().daoFloorPrices[daoId] = daoMetadataParam.floorPrice;
            daoInfo.nftMaxSupply = settingsStorage.nftMaxSupplies[daoMetadataParam.maxNftRank];
            daoInfo.daoUri = daoMetadataParam.projectUri;
            {
                if (
                    daoMetadataParam.royaltyFee < settingsStorage.minRoyaltyFeeRatioInBps
                        || daoMetadataParam.royaltyFee > settingsStorage.maxRoyaltyFeeRatioInBps
                ) revert RoyaltyFeeRatioOutOfRange();
            }
            daoInfo.royaltyFeeRatioInBps =
                daoMetadataParam.royaltyFee + uint96(settingsStorage.protocolRoyaltyFeeRatioInBps);
        }

        emit NewProject(
            daoId,
            daoMetadataParam.projectUri,
            daoInfo.token,
            daoInfo.nft,
            daoInfo.royaltyFeeRatioInBps,
            continuousDaoParam.isAncestorDao
        );

        protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][daoInfo.daoIndex] = daoId;

        DaoStorage.Layout storage daoStorage = DaoStorage.layout();

        {
            _createDaoAssetPool(daoId, daoInfo.daoIndex);
        }
        daoStorage.daoInfos[daoId].daoTag = DaoTag.BASIC_DAO;

        protocolStorage.uriExists[keccak256(abi.encodePacked(basicDaoParam.canvasUri))] = true;

        _createCanvas(
            CanvasStorage.layout().canvasInfos,
            daoId,
            basicDaoParam.canvasId,
            daoStorage.daoInfos[daoId].canvases.length,
            basicDaoParam.canvasUri,
            msg.sender
        );

        daoStorage.daoInfos[daoId].canvases.push(basicDaoParam.canvasId);
        BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();

        basicDaoStorage.basicDaoInfos[daoId].canvasIdOfSpecialNft = basicDaoParam.canvasId;
        // dailyMintCap
        basicDaoStorage.basicDaoInfos[daoId].roundMintCap = continuousDaoParam.dailyMintCap;
        basicDaoStorage.basicDaoInfos[daoId].unifiedPriceModeOff = continuousDaoParam.unifiedPriceModeOff;
        basicDaoStorage.basicDaoInfos[daoId].reserveNftNumber = continuousDaoParam.reserveNftNumber;
        basicDaoStorage.basicDaoInfos[daoId].unifiedPrice = continuousDaoParam.unifiedPrice;
        basicDaoStorage.basicDaoInfos[daoId].version = 16;
        basicDaoStorage.basicDaoInfos[daoId].exist = true;
        basicDaoStorage.basicDaoInfos[daoId].topUpMode = continuousDaoParam.topUpMode;
        basicDaoStorage.basicDaoInfos[daoId].needMintableWork = continuousDaoParam.needMintableWork;
        basicDaoStorage.basicDaoInfos[daoId].infiniteMode = continuousDaoParam.infiniteMode;
        basicDaoStorage.basicDaoInfos[daoId].outputPaymentMode = continuousDaoParam.outputPaymentMode;

        PoolStorage.PoolInfo storage poolInfo = PoolStorage.layout().poolInfos[daoStorage.daoInfos[daoId].daoFeePool];
        basicDaoStorage.basicDaoInfos[daoId].topUpInputToRedeemPoolRatio = poolInfo.defaultTopUpInputToRedeemPoolRatio;
        basicDaoStorage.basicDaoInfos[daoId].topUpOutputToTreasuryRatio = poolInfo.defaultTopUpOutputToTreasuryRatio;

        emit NewPools(
            daoId,
            basicDaoStorage.basicDaoInfos[daoId].daoAssetPool,
            daoStorage.daoInfos[daoId].daoFeePool,
            poolInfo.defaultTopUpInputToRedeemPoolRatio,
            poolInfo.defaultTopUpOutputToTreasuryRatio,
            BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken
        );
    }

    function _createProject(CreateAncestorDaoParam memory vars) internal {
        bytes32 daoId = vars.daoId;

        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        {
            if (vars.daoToken == address(0)) {
                daoInfo.token = _createERC20Token(vars.daoIndex, vars.daoName);
                IAccessControl(daoInfo.token).grantRole(keccak256("MINTER"), address(this));
                IAccessControl(daoInfo.token).grantRole(keccak256("BURNER"), address(this));
                ID4AChangeAdmin(daoInfo.token).changeAdmin(settingsStorage.assetOwner);
            } else {
                if (vars.daoToken == vars.inputToken) revert SameInputAndOutputToken();
                daoInfo.token = vars.daoToken;
                BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken = true;
            }

            address daoFeePool = settingsStorage.feePoolFactory.createD4AFeePool(
                string(abi.encodePacked("Redeem Pool for Semios Project ", LibString.toString(vars.daoIndex)))
            ); //this feepool is redeem pool for output token->input token

            D4AFeePool(payable(daoFeePool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

            ID4AChangeAdmin(daoFeePool).changeAdmin(settingsStorage.assetOwner);

            daoInfo.daoFeePool = daoFeePool;
            daoInfo.inputToken = vars.inputToken;

            _createTreasury(daoId, vars.daoIndex, vars.daoName, vars.daoToken, daoFeePool);
        }
    }

    function _createTreasury(
        bytes32 daoId,
        uint256 daoIndex,
        string memory daoName,
        address daoToken,
        address daoFeePool
    )
        internal
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        address treasury = settingsStorage.feePoolFactory.createD4AFeePool(
            string(abi.encodePacked("Treasury for Semios Project ", LibString.toString(daoIndex)))
        ); //this feepool is treasury

        D4AFeePool(payable(treasury)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

        ID4AChangeAdmin(treasury).changeAdmin(settingsStorage.assetOwner);

        if (daoToken == address(0)) {
            console2.log("minting token");
            D4AERC20(daoInfo.token).mint(treasury, settingsStorage.tokenMaxSupply);
        }

        PoolStorage.PoolInfo storage poolInfo = PoolStorage.layout().poolInfos[daoFeePool];
        poolInfo.treasury = treasury;

        address grantTreasuryNft = _createERC721Token(daoIndex, daoName, "SEMI.GT", false, 0);
        IAccessControl(grantTreasuryNft).grantRole(keccak256("ROYALTY"), address(this));
        IAccessControl(grantTreasuryNft).grantRole(keccak256("MINTER"), address(this));
        ID4AChangeAdmin(grantTreasuryNft).changeAdmin(settingsStorage.assetOwner);
        ID4AERC721(grantTreasuryNft).setContractUri(daoInfo.daoUri);
        ID4AChangeAdmin(grantTreasuryNft).transferOwnership(msg.sender);
        poolInfo.grantTreasuryNft = grantTreasuryNft;
        emit NewSemiTreasury(daoId, treasury, grantTreasuryNft, settingsStorage.tokenMaxSupply);
    }

    function _createContinuousProject(CreateContinuousDaoParam memory createContinuousDaoParam) internal {
        bytes32 daoId = createContinuousDaoParam.daoId;

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        daoInfo.token = createContinuousDaoParam.tokenAddress; //all subdaos use the same token
        daoInfo.daoFeePool = createContinuousDaoParam.feePoolAddress; //all subdaos use the same redeem pool
        daoInfo.inputToken = createContinuousDaoParam.inputToken; //all subdaos use the same payment token
    }

    function _createCanvas(
        mapping(bytes32 => CanvasStorage.CanvasInfo) storage canvasInfos,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 canvasIndex,
        string memory canvasUri,
        address to
    )
        internal
    {
        if (canvasInfos[canvasId].canvasExist) revert D4ACanvasAlreadyExist(canvasId);
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        {
            CanvasStorage.CanvasInfo storage canvasInfo = canvasInfos[canvasId];
            canvasInfo.daoId = daoId;
            canvasInfo.canvasUri = canvasUri;
            canvasInfo.index = canvasIndex + 1;
            settingsStorage.ownerProxy.initOwnerOf(canvasId, to);
            canvasInfo.canvasExist = true;
        }
        emit NewCanvas(daoId, canvasId, canvasUri);
    }

    function _createDaoERC721(
        bytes32 daoId,
        uint256 daoIndex,
        string memory daoName,
        bool needMintableWork,
        uint256 reserveNftNumber,
        string memory daoUri,
        string memory ownershipUri
    )
        internal
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        daoInfo.nft = _createERC721Token(daoIndex, daoName, "SEMI.N", needMintableWork, reserveNftNumber);
        IAccessControl(daoInfo.nft).grantRole(keccak256("ROYALTY"), address(this)); //this role never grant to the
            // user??
        IAccessControl(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

        ID4AERC721(daoInfo.nft).setContractUri(daoUri); //require by Opensea
        ID4AChangeAdmin(daoInfo.nft).changeAdmin(settingsStorage.assetOwner);
        ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender); //required by Opensea, only can change contract uri
        ID4AERC721(daoInfo.nft).mintItem(msg.sender, ownershipUri, 0, true);

        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        basicDaoInfo.grantAssetPoolNft = _createERC721Token(daoIndex, daoName, "SEMI.G", false, 0);

        IAccessControl(basicDaoInfo.grantAssetPoolNft).grantRole(keccak256("ROYALTY"), address(this)); //this role never
            // grant
            // to the
            // user??
        IAccessControl(basicDaoInfo.grantAssetPoolNft).grantRole(keccak256("MINTER"), address(this));

        ID4AERC721(basicDaoInfo.grantAssetPoolNft).setContractUri(daoUri);
        ID4AChangeAdmin(basicDaoInfo.grantAssetPoolNft).changeAdmin(settingsStorage.assetOwner);
        ID4AChangeAdmin(basicDaoInfo.grantAssetPoolNft).transferOwnership(msg.sender);
        emit NewSemiDaoErc721Address(daoId, daoInfo.nft, basicDaoInfo.grantAssetPoolNft);
    }

    function _createERC20Token(uint256 daoIndex, string memory daoName) internal returns (address) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked("SEMI.T", LibString.toString(daoIndex)));
        return settingsStorage.erc20Factory.createD4AERC20(name, sym);
    }

    function _createERC721Token(
        uint256 daoIndex,
        string memory daoName,
        string memory symbol,
        bool needMintableWork,
        uint256 startIndex
    )
        internal
        returns (address)
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked(symbol, LibString.toString(daoIndex)));
        return settingsStorage.erc721Factory.createD4AERC721(name, sym, needMintableWork ? startIndex : 0);
    }

    function _createDaoAssetPool(bytes32 daoId, uint256 daoIndex) internal returns (address) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        address daoAssetPool = settingsStorage.feePoolFactory.createD4AFeePool(
            string(abi.encodePacked("Dao Asset Pool for Semios Project ", LibString.toString(daoIndex)))
        ); //this feepool is dao asset pool for reward
        basicDaoInfo.daoAssetPool = daoAssetPool;
        D4AFeePool(payable(daoAssetPool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

        ID4AChangeAdmin(daoAssetPool).changeAdmin(settingsStorage.assetOwner);
        return daoAssetPool;
    }

    // ========================== optimized code =========================
    function _config(address protocol, CreateProjectLocalVars memory vars) internal {
        AllRatioParam memory allRatioParam =
            vars.topUpMode ? AllRatioParam(0, 0, 0, 0, 0, 0, 0, 0, 10_000, 0, 0, 0, 0, 0) : vars.allRatioParam;
        emit CreateProjectParamEmitted(
            vars.daoId,
            vars.daoFeePool,
            vars.token,
            vars.nft,
            vars.daoMetadataParam,
            vars.whitelist,
            vars.blacklist,
            vars.daoMintCapParam,
            vars.nftMinterCapInfo,
            vars.nftMinterCapIdInfo,
            vars.templateParam,
            vars.basicDaoParam,
            vars.actionType,
            allRatioParam
        );
        bytes32 daoId = vars.daoId;

        // setup ownership control permission
        IPDProtocolSetter(protocol).setDaoControlPermission(daoId, vars.nft, 0);
        if (TreeStorage.layout().treeInfos[daoId].isAncestorDao) {
            // treasury permission set for 1.6
            IPDProtocolSetter(protocol).setTreasuryControlPermission(daoId, vars.nft, 0);
        }

        ID4ASettingsReadable(protocol).permissionControl().addPermission(daoId, vars.whitelist, vars.blacklist);

        SetMintCapAndPermissionParam memory permissionVars;
        permissionVars.daoId = daoId;
        permissionVars.daoMintCap = vars.daoMintCapParam.daoMintCap;
        permissionVars.userMintCapParams = vars.daoMintCapParam.userMintCapParams;
        permissionVars.nftMinterCapInfo = vars.nftMinterCapInfo; //not support yet
        permissionVars.nftMinterCapIdInfo = vars.nftMinterCapIdInfo;
        permissionVars.whitelist = vars.whitelist;
        permissionVars.blacklist = vars.blacklist;
        permissionVars.unblacklist = Blacklist(new address[](0), new address[](0));
        uint256 actionType = vars.actionType;
        if ((actionType & 0x4) != 0) {
            ID4AProtocolSetter(protocol).setMintCapAndPermission(
                permissionVars.daoId,
                permissionVars.daoMintCap,
                permissionVars.userMintCapParams,
                permissionVars.nftMinterCapInfo,
                permissionVars.nftMinterCapIdInfo,
                permissionVars.whitelist,
                permissionVars.blacklist,
                permissionVars.unblacklist
            );
        }

        // to get d4aswapFactory, royaltySplitterFactory and royaltySplitterOwner
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        if ((actionType & 0x8) != 0) {
            settingsStorage.d4aswapFactory.createPair(vars.token, WETH);
        }

        IPDProtocolSetter(protocol).setRatio(daoId, vars.allRatioParam);

        // setup template
        ID4AProtocolSetter(protocol).setTemplate(daoId, vars.templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(protocol).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(protocol).tradeProtocolFeeRatio();

        address splitter;
        if (!BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken) {
            splitter = settingsStorage.royaltySplitterFactory.createD4ARoyaltySplitter(
                ID4ASettingsReadable(protocol).protocolFeePool(),
                protocolRoyaltyFeeRatioInBps,
                vars.daoFeePool,
                uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
            );
        } else {
            splitter = settingsStorage.royaltySplitterFactory.createD4ARoyaltySplitter(
                ID4ASettingsReadable(protocol).protocolFeePool(),
                protocolRoyaltyFeeRatioInBps,
                vars.daoAssetPool,
                uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
            );
        }
        settingsStorage.royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(settingsStorage.royaltySplitterOwner);
        ID4AERC721(vars.nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }
}

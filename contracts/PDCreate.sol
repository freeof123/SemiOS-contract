// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// interfaces
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { DaoTag } from "contracts/interface/D4AEnums.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolSetter } from "contracts/interface/IPDProtocolSetter.sol";
import { ID4AChangeAdmin } from "./interface/ID4AChangeAdmin.sol";
import { BASIS_POINT, BASIC_DAO_RESERVE_NFT_NUMBER } from "contracts/interface/D4AConstants.sol";
import {
    DaoMetadataParam,
    Whitelist,
    Blacklist,
    DaoMintCapParam,
    DaoETHAndERC20SplitRatioParam,
    SetMintCapAndPermissionParam,
    ContinuousDaoParam,
    NftMinterCapInfo,
    SetRatioParam,
    TemplateParam,
    BasicDaoParam,
    AllRatioParam,
    SetChildrenParam
} from "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

// setting
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";

// storages
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { ProtocolStorage } from "contracts/storages/ProtocolStorage.sol";
import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RoundStorage } from "contracts/storages/RoundStorage.sol";

import { ProtocolChecker } from "contracts/ProtocolChecker.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { LibString } from "solady/utils/LibString.sol";

import { D4AERC20 } from "./D4AERC20.sol";
import { D4AERC721 } from "./D4AERC721.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";

//import "forge-std/Test.sol";

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
    DaoETHAndERC20SplitRatioParam splitRatioParam;
    TemplateParam templateParam;
    BasicDaoParam basicDaoParam;
    AllRatioParam allRatioParam;
    uint256 actionType;
    bool needMintableWork;
    uint256 dailyMintCap;
    uint8 version;
}

struct CreateAncestorDaoParam {
    uint256 daoIndex;
    string daoUri;
    uint256 initTokenSupplyRatio;
    string daoName;
    bool needMintableWork;
    address daoToken;
    uint256 reserveNftNumber;
}

struct CreateContinuousDaoParam {
    uint256 daoIndex;
    string daoUri;
    uint256 initTokenSupplyRatio;
    string daoName;
    address tokenAddress;
    address feePoolAddress;
    bool needMintableWork;
    uint256 dailyMintCap;
    uint256 reserveNftNumber;
}

contract PDCreate is IPDCreate, ProtocolChecker, ReentrancyGuard {
    address public immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    /**
     * @dev create continuous dao
     * @param existDaoId basic dao id
     * @param daoMetadataParam metadata param for dao
     * @param whitelist the whitelist
     * @param blacklist the blacklist
     * @param daoMintCapParam the mint cap param for dao
     * @param templateParam the template param
     * @param basicDaoParam the param for basic dao
     * @param continuousDaoParam the param for continuous dao
     * @param actionType the type of action
     */
    function createDao(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        ContinuousDaoParam calldata continuousDaoParam,
        AllRatioParam calldata allRatioParam,
        uint256 actionType
    )
        public
        payable
        override
        nonReentrant
        returns (bytes32 daoId)
    {
        address protocol = address(this);

        CreateProjectLocalVars memory vars;
        vars.existDaoId = existDaoId;
        vars.daoMetadataParam = daoMetadataParam;
        vars.whitelist = whitelist;
        vars.blacklist = blacklist;
        vars.daoMintCapParam = daoMintCapParam;
        vars.nftMinterCapInfo = nftMinterCapInfo;
        vars.templateParam = templateParam;
        vars.basicDaoParam = basicDaoParam;
        vars.actionType = actionType;
        vars.needMintableWork = continuousDaoParam.needMintableWork;
        vars.dailyMintCap = continuousDaoParam.dailyMintCap;
        vars.allRatioParam = allRatioParam;

        if (daoMetadataParam.floorPrice == 0) revert CannotUseZeroFloorPrice();

        if (continuousDaoParam.reserveNftNumber == 0 && continuousDaoParam.needMintableWork) {
            revert ZeroNftReserveNumber(); //要么不开，开了就不能传0
        }

        if (continuousDaoParam.erc20PaymentMode && continuousDaoParam.topUpMode) {
            revert PaymentModeAndTopUpModeCannotBeBothOn();
        }
        daoId = _createDao(existDaoId, daoMetadataParam, basicDaoParam, continuousDaoParam, actionType);

        vars.daoId = daoId;

        // Use the exist DaoFeePool and DaoToken
        vars.daoFeePool = ID4AProtocolReadable(protocol).getDaoFeePool(daoId);
        vars.daoAssetPool = IPDProtocolReadable(protocol).getDaoAssetPool(daoId);
        vars.token = ID4AProtocolReadable(protocol).getDaoToken(daoId);
        vars.nft = ID4AProtocolReadable(protocol).getDaoNft(daoId);

        emit CreateContinuousProjectParamEmitted(
            vars.existDaoId,
            vars.daoId,
            vars.dailyMintCap,
            vars.needMintableWork,
            continuousDaoParam.unifiedPriceModeOff,
            ID4AProtocolReadable(protocol).getDaoUnifiedPrice(daoId),
            continuousDaoParam.reserveNftNumber,
            continuousDaoParam.topUpMode,
            continuousDaoParam.infiniteMode,
            continuousDaoParam.erc20PaymentMode
        );
        _config(protocol, vars);

        //if (!continuousDaoParam.isAncestorDao) {
        IPDProtocolSetter(protocol).setChildren(
            daoId,
            SetChildrenParam(
                continuousDaoParam.childrenDaoId,
                continuousDaoParam.childrenDaoRatiosERC20,
                continuousDaoParam.childrenDaoRatiosETH,
                continuousDaoParam.redeemPoolRatioETH,
                continuousDaoParam.selfRewardRatioERC20,
                continuousDaoParam.selfRewardRatioETH
            )
        );
        //}
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
        address feePoolAddress = DaoStorage.layout().daoInfos[existDaoId].daoFeePool;
        address tokenAddress = DaoStorage.layout().daoInfos[existDaoId].token;

        super._checkPauseStatus();
        super._checkUriNotExist(daoMetadataParam.projectUri);
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

        if (daoMetadataParam.startBlock != 0 && daoMetadataParam.startBlock < block.number) {
            revert StartBlockAlreadyPassed();
        }
        uint256 daoIndex;
        if (actionType & 0x1 != 0) {
            SettingsStorage.Layout storage l = SettingsStorage.layout();
            if (daoMetadataParam.projectIndex >= l.reservedDaoAmount) revert DaoIndexTooLarge();
            if (((protocolStorage.d4aDaoIndexBitMap >> daoMetadataParam.projectIndex) & 1) != 0) {
                revert DaoIndexAlreadyExist();
            }
            protocolStorage.d4aDaoIndexBitMap |= (1 << daoMetadataParam.projectIndex);
            protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;
            daoIndex = daoMetadataParam.projectIndex;
        } else {
            daoIndex = protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];
            ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];
        }
        CreateContinuousDaoParam memory createContinuousDaoParam;
        if (!continuousDaoParam.isAncestorDao) {
            if (!InheritTreeStorage.layout().inheritTreeInfos[existDaoId].isAncestorDao) revert NotAncestorDao(); //Todo

            createContinuousDaoParam.daoIndex = daoIndex;
            createContinuousDaoParam.daoUri = daoMetadataParam.projectUri;
            createContinuousDaoParam.initTokenSupplyRatio = basicDaoParam.initTokenSupplyRatio;
            createContinuousDaoParam.daoName = basicDaoParam.daoName;
            createContinuousDaoParam.tokenAddress = tokenAddress;
            createContinuousDaoParam.feePoolAddress = feePoolAddress;
            createContinuousDaoParam.needMintableWork = continuousDaoParam.needMintableWork;
            createContinuousDaoParam.dailyMintCap = continuousDaoParam.dailyMintCap;
            createContinuousDaoParam.reserveNftNumber = continuousDaoParam.reserveNftNumber;
            daoId = _createContinuousProject(createContinuousDaoParam);
            InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor = existDaoId;
            InheritTreeStorage.layout().inheritTreeInfos[existDaoId].familyDaos.push(daoId);
            BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken =
                BasicDaoStorage.layout().basicDaoInfos[existDaoId].isThirdPartyToken;
        } else {
            daoId = _createProject(
                CreateAncestorDaoParam(
                    daoIndex,
                    daoMetadataParam.projectUri,
                    basicDaoParam.initTokenSupplyRatio,
                    basicDaoParam.daoName,
                    continuousDaoParam.needMintableWork,
                    continuousDaoParam.daoToken,
                    continuousDaoParam.reserveNftNumber
                )
            );
            InheritTreeStorage.layout().inheritTreeInfos[daoId].isAncestorDao = true;
            InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor = daoId;
            InheritTreeStorage.layout().inheritTreeInfos[daoId].familyDaos.push(daoId);
        }
        //common initializaitions
        {
            DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
            SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
            RoundStorage.RoundInfo storage roundInfo = RoundStorage.layout().roundInfos[daoId];
            if (daoMetadataParam.duration == 0) revert DurationIsZero();
            roundInfo.roundDuration = daoMetadataParam.duration;
            roundInfo.roundInLastModify = 1;
            roundInfo.blockInLastModify = block.number;

            daoInfo.startBlock = daoMetadataParam.startBlock == 0 ? block.number : daoMetadataParam.startBlock;
            daoInfo.mintableRound = daoMetadataParam.mintableRounds;
            PriceStorage.layout().daoFloorPrices[daoId] = daoMetadataParam.floorPrice;
            daoInfo.nftMaxSupply = settingsStorage.nftMaxSupplies[daoMetadataParam.maxNftRank];
            daoInfo.daoUri = daoMetadataParam.projectUri;
            {
                uint256 protocolRoyaltyFeeRatioInBps = settingsStorage.protocolRoyaltyFeeRatioInBps;
                if (
                    daoMetadataParam.royaltyFee < settingsStorage.minRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                        || daoMetadataParam.royaltyFee
                            > settingsStorage.maxRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                ) revert RoyaltyFeeRatioOutOfRange();
            }
            daoInfo.royaltyFeeRatioInBps = daoMetadataParam.royaltyFee;
            daoInfo.daoIndex = daoIndex;
        }

        emit NewProject(
            daoId,
            daoMetadataParam.projectUri,
            DaoStorage.layout().daoInfos[daoId].token,
            DaoStorage.layout().daoInfos[daoId].nft,
            daoMetadataParam.royaltyFee,
            continuousDaoParam.isAncestorDao
        );

        protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][daoIndex] = daoId;

        DaoStorage.Layout storage daoStorage = DaoStorage.layout();

        {
            address daoAssetPool = _createDaoAssetPool(daoId, daoIndex);
            if (continuousDaoParam.isAncestorDao && !BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken) {
                daoStorage.daoInfos[daoId].tokenMaxSupply =
                    (SettingsStorage.layout().tokenMaxSupply * basicDaoParam.initTokenSupplyRatio) / BASIS_POINT;
                D4AERC20(daoStorage.daoInfos[daoId].token).mint(daoAssetPool, daoStorage.daoInfos[daoId].tokenMaxSupply);
            }
            if (
                !continuousDaoParam.isAncestorDao && !BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken
                    && msg.sender == SettingsStorage.layout().ownerProxy.ownerOf(existDaoId)
            ) {
                daoStorage.daoInfos[daoId].tokenMaxSupply =
                    (SettingsStorage.layout().tokenMaxSupply * basicDaoParam.initTokenSupplyRatio) / BASIS_POINT;
                D4AERC20(daoStorage.daoInfos[daoId].token).mint(daoAssetPool, daoStorage.daoInfos[daoId].tokenMaxSupply);
            }
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
        basicDaoStorage.basicDaoInfos[daoId].version = 14;
        basicDaoStorage.basicDaoInfos[daoId].exist = true;
        basicDaoStorage.basicDaoInfos[daoId].topUpMode = continuousDaoParam.topUpMode;
        basicDaoStorage.basicDaoInfos[daoId].needMintableWork = continuousDaoParam.needMintableWork;
        basicDaoStorage.basicDaoInfos[daoId].infiniteMode = continuousDaoParam.infiniteMode;
        basicDaoStorage.basicDaoInfos[daoId].erc20PaymentMode = continuousDaoParam.erc20PaymentMode;

        emit NewPools(
            daoId,
            basicDaoStorage.basicDaoInfos[daoId].daoAssetPool,
            daoStorage.daoInfos[daoId].daoFeePool,
            BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken
        );
    }

    function _createProject(CreateAncestorDaoParam memory vars) internal returns (bytes32 daoId) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            daoInfo.daoUri = vars.daoUri;
            daoInfo.daoIndex = vars.daoIndex;
            if (vars.daoToken == address(0)) {
                daoInfo.token = _createERC20Token(vars.daoIndex, vars.daoName);
                D4AERC20(daoInfo.token).grantRole(keccak256("MINTER"), address(this));
                D4AERC20(daoInfo.token).grantRole(keccak256("BURNER"), address(this));
                ID4AChangeAdmin(daoInfo.token).changeAdmin(settingsStorage.assetOwner);
            } else {
                daoInfo.token = vars.daoToken;
                BasicDaoStorage.layout().basicDaoInfos[daoId].isThirdPartyToken = true;
            }

            address daoFeePool = settingsStorage.feePoolFactory.createD4AFeePool(
                string(abi.encodePacked("Redeem Pool for Semios Project ", LibString.toString(vars.daoIndex)))
            ); //this feepool is redeem pool for erc20->eth

            D4AFeePool(payable(daoFeePool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

            ID4AChangeAdmin(daoFeePool).changeAdmin(settingsStorage.assetOwner);

            daoInfo.daoFeePool = daoFeePool;

            settingsStorage.ownerProxy.initOwnerOf(daoId, msg.sender); //before: createprojectproxy, now :user

            daoInfo.nft = _createERC721Token(vars.daoIndex, vars.daoName, vars.needMintableWork, vars.reserveNftNumber);
            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), address(this)); //this role never grant to the user??
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(vars.daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(settingsStorage.assetOwner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender); //before: createprojectproxy,now :user
            //We copy from setting in case setting may change later.
            daoInfo.daoExist = true;
        }
    }

    function _createContinuousProject(CreateContinuousDaoParam memory createContinuousDaoParam)
        internal
        returns (bytes32 daoId)
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            daoInfo.daoUri = createContinuousDaoParam.daoUri;
            daoInfo.daoIndex = createContinuousDaoParam.daoIndex;
            daoInfo.token = createContinuousDaoParam.tokenAddress;
            address daoFeePool = createContinuousDaoParam.feePoolAddress;

            daoInfo.daoFeePool = daoFeePool; //all subdaos use the same redeem pool

            settingsStorage.ownerProxy.initOwnerOf(daoId, msg.sender);

            daoInfo.nft = _createERC721Token(
                createContinuousDaoParam.daoIndex,
                createContinuousDaoParam.daoName,
                createContinuousDaoParam.needMintableWork,
                createContinuousDaoParam.reserveNftNumber
            );

            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), address(this));
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(createContinuousDaoParam.daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(settingsStorage.assetOwner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender);
            //We copy from setting in case setting may change later.

            daoInfo.daoExist = true;
        }
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

    function _createERC20Token(uint256 daoIndex, string memory daoName) internal returns (address) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked("SEMI.T", LibString.toString(daoIndex)));
        return settingsStorage.erc20Factory.createD4AERC20(name, sym, address(this));
    }

    function _createERC721Token(
        uint256 daoIndex,
        string memory daoName,
        bool needMintableWork,
        uint256 startIndex
    )
        internal
        returns (address)
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked("SEMI.N", LibString.toString(daoIndex)));
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
            vars.templateParam,
            vars.basicDaoParam,
            vars.actionType,
            vars.allRatioParam
        );

        bytes32 daoId = vars.daoId;
        ID4ASettingsReadable(protocol).permissionControl().addPermission(daoId, vars.whitelist, vars.blacklist);

        SetMintCapAndPermissionParam memory permissionVars;
        permissionVars.daoId = daoId;
        permissionVars.daoMintCap = vars.daoMintCapParam.daoMintCap;
        permissionVars.userMintCapParams = vars.daoMintCapParam.userMintCapParams;
        permissionVars.nftMinterCapInfo = vars.nftMinterCapInfo; //not support yet

        // * sort
        // if (isBasicDao) {
        //     NftMinterCapInfo[] memory nftMinterCapInfo;
        //     nftMinterCapInfo = new NftMinterCapInfo[](1);
        //     nftMinterCapInfo[0] = NftMinterCapInfo({ nftAddress: vars.nft, nftMintCap: 5 });
        //     permissionVars.nftMinterCapInfo = nftMinterCapInfo;
        // }

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

        SetRatioParam memory ratioVars;
        ratioVars.daoId = daoId;
        ratioVars.daoCreatorERC20Ratio = vars.splitRatioParam.daoCreatorERC20Ratio;
        ratioVars.canvasCreatorERC20Ratio = vars.splitRatioParam.canvasCreatorERC20Ratio;
        ratioVars.nftMinterERC20Ratio = vars.splitRatioParam.nftMinterERC20Ratio;
        ratioVars.daoFeePoolETHRatio = vars.splitRatioParam.daoFeePoolETHRatio;
        ratioVars.daoFeePoolETHRatioFlatPrice = vars.splitRatioParam.daoFeePoolETHRatioFlatPrice;

        // if ((actionType & 0x10) != 0) {
        //     ID4AProtocolSetter(protocol).setRatio(
        //         ratioVars.daoId,
        //         ratioVars.daoCreatorERC20Ratio,
        //         ratioVars.canvasCreatorERC20Ratio,
        //         ratioVars.nftMinterERC20Ratio,
        //         ratioVars.daoFeePoolETHRatio,
        //         ratioVars.daoFeePoolETHRatioFlatPrice
        //     );
        // }

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

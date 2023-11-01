// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// interfaces
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { IPDCreateFunding } from "contracts/interface/IPDCreateFunding.sol";
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
    AllRatioForFundingParam
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

import { ProtocolChecker } from "contracts/ProtocolChecker.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { LibString } from "solady/utils/LibString.sol";

import { D4AERC20 } from "./D4AERC20.sol";
import { D4AERC721 } from "./D4AERC721.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";

struct CreateProjectLocalVars {
    bytes32 existDaoId;
    bytes32 daoId;
    address daoFeePool;
    address token;
    address nft;
    DaoMetadataParam daoMetadataParam;
    Whitelist whitelist;
    Blacklist blacklist;
    DaoMintCapParam daoMintCapParam;
    DaoETHAndERC20SplitRatioParam splitRatioParam;
    TemplateParam templateParam;
    BasicDaoParam basicDaoParam;
    AllRatioForFundingParam allRatioForFundingParam;
    uint256 actionType;
    bool needMintableWork;
    uint256 dailyMintCap;
    uint8 version;
}

struct CreateContinuousDaoParam {
    uint256 startRound;
    uint256 mintableRound;
    uint256 daoFloorPriceRank;
    uint256 nftMaxSupplyRank;
    uint96 royaltyFeeRatioInBps;
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

contract PDCreateFunding is IPDCreateFunding, ProtocolChecker, ReentrancyGuard {
    address public immutable WETH;

    constructor(address _weth) {
        WETH = _weth;
    }

    /**
     * @dev create basic dao
     * @param daoMetadataParam metadata param for dao
     * @param whitelist the whitelist
     * @param blacklist the blacklist
     * @param daoMintCapParam the mint cap param for dao
     * splitRatioParam the split ratio param
     * @param templateParam the template param
     * @param basicDaoParam the param for basic dao
     * @param actionType the type of action
     */

    function createBasicDaoForFunding(
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        //DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        AllRatioForFundingParam calldata allRatioForFundingParam,
        uint256 actionType
    )
        public
        payable
        override
        nonReentrant
        returns (bytes32 daoId)
    {
        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) revert ZeroFloorPriceCannotUseLinearPriceVariation();

        daoId = _createBasicDao(daoMetadataParam, basicDaoParam);

        CreateProjectLocalVars memory vars;

        vars.daoId = daoId;
        vars.daoMetadataParam = daoMetadataParam;
        vars.whitelist = whitelist;
        vars.blacklist = blacklist;
        vars.daoMintCapParam = daoMintCapParam;
        //vars.splitRatioParam = splitRatioParam;
        vars.templateParam = templateParam;
        vars.basicDaoParam = basicDaoParam;
        vars.actionType = actionType;
        vars.allRatioForFundingParam = allRatioForFundingParam;

        address protocol = address(this); // gas saving
        vars.daoFeePool = ID4AProtocolReadable(protocol).getDaoFeePool(daoId);
        vars.token = ID4AProtocolReadable(protocol).getDaoToken(daoId);
        vars.nft = ID4AProtocolReadable(protocol).getDaoNft(daoId);
        vars.version = IPDProtocolReadable(protocol).getDaoVersion(daoId);

        vars.dailyMintCap = ID4AProtocolReadable(protocol).getDaoDailyMintCap(daoId);
        bool _unifiedPriceModeOff = ID4AProtocolReadable(protocol).getDaoUnifiedPriceModeOff(daoId);
        uint256 _unifiedPrice = ID4AProtocolReadable(protocol).getDaoUnifiedPrice(daoId);
        uint256 _reserveNftNumber = ID4AProtocolReadable(protocol).getDaoReserveNftNumber(daoId);

        emit CreateContinuousProjectParamEmittedForFunding(
            daoId, daoId, vars.dailyMintCap, true, _unifiedPriceModeOff, _unifiedPrice, _reserveNftNumber
        );

        _config(protocol, vars, true);
    }

    /**
     * @dev create continuous dao
     * @param existDaoId basic dao id
     * @param daoMetadataParam metadata param for dao
     * @param whitelist the whitelist
     * @param blacklist the blacklist
     * @param daoMintCapParam the mint cap param for dao
     *  //* splitRatioParam the split ratio param
     * @param templateParam the template param
     * @param basicDaoParam the param for basic dao
     * @param continuousDaoParam the param for continuous dao
     * @param actionType the type of action
     */
    function createContinuousDaoForFunding(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        //DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        ContinuousDaoParam calldata continuousDaoParam,
        AllRatioForFundingParam calldata allRatioForFundingParam,
        uint256 actionType
    )
        public
        payable
        override
        nonReentrant
        returns (bytes32 daoId)
    {
        address protocol = address(this);
        // if (ID4ASettingsReadable(protocol).ownerProxy().ownerOf(existDaoId) != msg.sender) {
        //     revert NotBasicDaoOwner();
        // }
        CreateProjectLocalVars memory vars;
        vars.existDaoId = existDaoId;
        vars.daoMetadataParam = daoMetadataParam;
        vars.whitelist = whitelist;
        vars.blacklist = blacklist;
        vars.daoMintCapParam = daoMintCapParam;
        //vars.splitRatioParam = splitRatioParam;
        vars.templateParam = templateParam;
        vars.basicDaoParam = basicDaoParam;
        vars.actionType = actionType;
        vars.needMintableWork = continuousDaoParam.needMintableWork;
        vars.dailyMintCap = continuousDaoParam.dailyMintCap;
        vars.allRatioForFundingParam = allRatioForFundingParam;

        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) revert ZeroFloorPriceCannotUseLinearPriceVariation();

        if (continuousDaoParam.reserveNftNumber == 0 && continuousDaoParam.needMintableWork) {
            revert ZeroNftReserveNumber(); //要么不开，开了就不能传0
        }
        daoId = _createContinuousDao(existDaoId, daoMetadataParam, basicDaoParam, continuousDaoParam);
        vars.daoId = daoId;

        // Use the exist DaoFeePool and DaoToken
        vars.daoFeePool = ID4AProtocolReadable(protocol).getDaoFeePool(existDaoId);
        vars.token = ID4AProtocolReadable(protocol).getDaoToken(existDaoId);
        vars.nft = ID4AProtocolReadable(protocol).getDaoNft(daoId);
        vars.version = IPDProtocolReadable(protocol).getDaoVersion(daoId);

        emit CreateContinuousProjectParamEmittedForFunding(
            vars.existDaoId,
            vars.daoId,
            vars.dailyMintCap,
            vars.needMintableWork,
            continuousDaoParam.unifiedPriceModeOff,
            ID4AProtocolReadable(protocol).getDaoUnifiedPrice(daoId),
            continuousDaoParam.reserveNftNumber
        );

        _config(protocol, vars, false);

        IPDProtocolSetter(protocol).setChildren(
            daoId,
            continuousDaoParam.childrenDaoId,
            continuousDaoParam.childrenDaoRatios,
            continuousDaoParam.redeemPoolRatio
        );
    }

    //================================ internal functions ===============================

    function _createBasicDao(
        DaoMetadataParam calldata daoMetadataParam,
        BasicDaoParam calldata basicDaoParam
    )
        internal
        returns (bytes32 daoId)
    {
        {
            super._checkPauseStatus();
            super._checkUriNotExist(daoMetadataParam.projectUri);
        }

        {
            ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
            protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

            daoId = _createProject(
                daoMetadataParam.startDrb,
                daoMetadataParam.mintableRounds,
                daoMetadataParam.floorPriceRank,
                daoMetadataParam.maxNftRank,
                daoMetadataParam.royaltyFee,
                protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)],
                daoMetadataParam.projectUri,
                basicDaoParam.initTokenSupplyRatio,
                basicDaoParam.daoName
            );

            {
                InheritTreeStorage.InheritTreeInfo storage treeInfo =
                    InheritTreeStorage.layout().inheritTreeInfos[daoId];
                treeInfo.isAncestorDao = true;
                treeInfo.familyDaos.push(daoId);
            }

            protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][protocolStorage.lastestDaoIndexes[uint8(
                DaoTag.BASIC_DAO
            )]] = daoId;
            ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];

            DaoStorage.Layout storage daoStorage = DaoStorage.layout();

            {
                address daoAssetPool =
                    _createDaoAssetPool(daoId, protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)]);
                D4AERC20(daoStorage.daoInfos[daoId].token).mint(daoAssetPool, daoStorage.daoInfos[daoId].tokenMaxSupply);
            }

            {
                address fundingPool =
                    _createFundingPool(daoId, protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)]);
            }

            daoStorage.daoInfos[daoId].daoMintInfo.NFTHolderMintCap = 5;
            daoStorage.daoInfos[daoId].daoTag = DaoTag.BASIC_DAO;

            protocolStorage.uriExists[keccak256(abi.encodePacked(basicDaoParam.canvasUri))] = true;

            _createCanvas(
                CanvasStorage.layout().canvasInfos,
                daoId,
                basicDaoParam.canvasId,
                daoStorage.daoInfos[daoId].canvases.length,
                basicDaoParam.canvasUri,
                msg.sender //canvas owner, before :proxy , now :user
            );

            daoStorage.daoInfos[daoId].canvases.push(basicDaoParam.canvasId);
        }

        {
            BasicDaoStorage.Layout storage basicDaoStorage = BasicDaoStorage.layout();
            basicDaoStorage.basicDaoInfos[daoId].basicDaoExist = true;
            basicDaoStorage.basicDaoInfos[daoId].canvasIdOfSpecialNft = basicDaoParam.canvasId;
            basicDaoStorage.basicDaoInfos[daoId].dailyMintCap = 10_000;
            basicDaoStorage.basicDaoInfos[daoId].version = 13;
        }
    }

    function _createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        uint256 daoIndex,
        string memory daoUri,
        uint256 initTokenSupplyRatio,
        string memory daoName
    )
        internal
        returns (bytes32 daoId)
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        {
            if (mintableRound > settingsStorage.maxMintableRound) revert ExceedMaxMintableRound();
            {
                uint256 protocolRoyaltyFeeRatioInBps = settingsStorage.protocolRoyaltyFeeRatioInBps;
                if (
                    royaltyFeeRatioInBps < settingsStorage.minRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                        || royaltyFeeRatioInBps > settingsStorage.maxRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                ) revert RoyaltyFeeRatioOutOfRange();
            }
        }

        //TODO: who is `tx.origin`
        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            if (startRound < settingsStorage.drb.currentRound()) revert StartRoundAlreadyPassed();
            daoInfo.startRound = startRound;
            daoInfo.mintableRound = mintableRound;
            daoInfo.nftMaxSupply = settingsStorage.nftMaxSupplies[nftMaxSupplyRank];
            daoInfo.daoUri = daoUri;
            daoInfo.royaltyFeeRatioInBps = royaltyFeeRatioInBps;
            daoInfo.daoIndex = daoIndex;
            daoInfo.token = _createERC20Token(daoIndex, daoName);

            //TODO: whether to modify `address(this)`
            D4AERC20(daoInfo.token).grantRole(keccak256("MINTER"), address(this));
            D4AERC20(daoInfo.token).grantRole(keccak256("BURNER"), address(this));

            address daoFeePool = settingsStorage.feePoolFactory.createD4AFeePool(
                string(abi.encodePacked("Redeem Pool for DAO4Art Project ", LibString.toString(daoIndex)))
            ); //this feepool is redeem pool for erc20->eth

            D4AFeePool(payable(daoFeePool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

            ID4AChangeAdmin(daoFeePool).changeAdmin(settingsStorage.assetOwner);
            ID4AChangeAdmin(daoInfo.token).changeAdmin(settingsStorage.assetOwner);

            daoInfo.daoFeePool = daoFeePool;

            settingsStorage.ownerProxy.initOwnerOf(daoId, msg.sender); //before: createprojectproxy, now :user

            bool needMintableWork = true;
            daoInfo.nft = _createERC721Token(daoIndex, daoName, needMintableWork, BASIC_DAO_RESERVE_NFT_NUMBER);
            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), address(this)); //this role never grant to the user??
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(settingsStorage.assetOwner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender); //before: createprojectproxy,now :user
            //We copy from setting in case setting may change later.
            daoInfo.tokenMaxSupply = (settingsStorage.tokenMaxSupply * initTokenSupplyRatio) / BASIS_POINT;

            if (daoFloorPriceRank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[daoId] = settingsStorage.daoFloorPrices[daoFloorPriceRank];
            }

            daoInfo.daoExist = true;
            emit NewProjectForFunding(daoId, daoUri, daoFeePool, daoInfo.token, daoInfo.nft, royaltyFeeRatioInBps);
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
        emit NewCanvasForFunding(daoId, canvasId, canvasUri);
    }

    function _createERC20Token(uint256 daoIndex, string memory daoName) internal returns (address) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        string memory name = daoName;
        string memory sym = string(abi.encodePacked("PDAO.T", LibString.toString(daoIndex)));
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
        string memory sym = string(abi.encodePacked("PDAO.N", LibString.toString(daoIndex)));
        return settingsStorage.erc721Factory.createD4AERC721(name, sym, needMintableWork ? startIndex : 0);
    }

    function _createContinuousDao(
        bytes32 existDaoId,
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam,
        ContinuousDaoParam memory continuousDaoParam
    )
        internal
        returns (bytes32 daoId)
    {
        // here need to check daoid if exist // we checked it in this function
        address feePoolAddress = DaoStorage.layout().daoInfos[existDaoId].daoFeePool;
        address tokenAddress = DaoStorage.layout().daoInfos[existDaoId].token;

        _checkPauseStatus();
        _checkUriNotExist(daoMetadataParam.projectUri);
        ProtocolStorage.Layout storage protocolStorage = ProtocolStorage.layout();
        protocolStorage.uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;

        CreateContinuousDaoParam memory createContinuousDaoParam;
        {
            createContinuousDaoParam.startRound = daoMetadataParam.startDrb;
            createContinuousDaoParam.mintableRound = daoMetadataParam.mintableRounds;
            createContinuousDaoParam.daoFloorPriceRank = daoMetadataParam.floorPriceRank;
            createContinuousDaoParam.nftMaxSupplyRank = daoMetadataParam.maxNftRank;
            createContinuousDaoParam.royaltyFeeRatioInBps = daoMetadataParam.royaltyFee;
            createContinuousDaoParam.daoIndex = protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];
            createContinuousDaoParam.daoUri = daoMetadataParam.projectUri;
            //createContinuousDaoParam.initTokenSupplyRatio = basicDaoParam.initTokenSupplyRatio;
            createContinuousDaoParam.daoName = basicDaoParam.daoName;
            createContinuousDaoParam.tokenAddress = tokenAddress;
            createContinuousDaoParam.feePoolAddress = feePoolAddress;
            createContinuousDaoParam.needMintableWork = continuousDaoParam.needMintableWork;
            createContinuousDaoParam.dailyMintCap = continuousDaoParam.dailyMintCap;
            createContinuousDaoParam.reserveNftNumber = continuousDaoParam.reserveNftNumber;
        }
        daoId = _createContinuousProject(createContinuousDaoParam);

        {
            InheritTreeStorage.InheritTreeInfo storage treeInfo = InheritTreeStorage.layout().inheritTreeInfos[daoId];
            treeInfo.ancestor = existDaoId;
            // require(
            //     InheritTreeStorage.layout().inheritTreeInfos[existDaoId].ancestor == bytes32(0),
            //     "must inherit basic dao"
            // );
            InheritTreeStorage.layout().inheritTreeInfos[existDaoId].familyDaos.push(daoId);
        }

        protocolStorage.daoIndexToIds[uint8(DaoTag.BASIC_DAO)][protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)]]
        = daoId;
        ++protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)];

        DaoStorage.Layout storage daoStorage = DaoStorage.layout();

        {
            _createDaoAssetPool(daoId, protocolStorage.lastestDaoIndexes[uint8(DaoTag.BASIC_DAO)]);
            //D4AERC20(daoStorage.daoInfos[daoId].token).mint(daoAssetPool, daoStorage.daoInfos[daoId].tokenMaxSupply);
        }
        //daoStorage.daoInfos[daoId].daoMintInfo.NFTHolderMintCap = 5;
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

        if (!basicDaoStorage.basicDaoInfos[existDaoId].basicDaoExist) revert NotBasicDao();

        basicDaoStorage.basicDaoInfos[daoId].canvasIdOfSpecialNft = basicDaoParam.canvasId;
        // dailyMintCap
        basicDaoStorage.basicDaoInfos[daoId].dailyMintCap = continuousDaoParam.dailyMintCap;
        basicDaoStorage.basicDaoInfos[daoId].unifiedPriceModeOff = continuousDaoParam.unifiedPriceModeOff;
        basicDaoStorage.basicDaoInfos[daoId].reserveNftNumber = continuousDaoParam.reserveNftNumber;
        basicDaoStorage.basicDaoInfos[daoId].unifiedPrice = continuousDaoParam.unifiedPrice;
        basicDaoStorage.basicDaoInfos[daoId].version = 13;
    }

    function _createContinuousProject(CreateContinuousDaoParam memory createContinuousDaoParam)
        internal
        returns (bytes32 daoId)
    {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();

        if (createContinuousDaoParam.mintableRound > settingsStorage.maxMintableRound) revert ExceedMaxMintableRound();
        {
            uint256 protocolRoyaltyFeeRatioInBps = settingsStorage.protocolRoyaltyFeeRatioInBps;
            if (
                createContinuousDaoParam.royaltyFeeRatioInBps
                    < settingsStorage.minRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
                    || createContinuousDaoParam.royaltyFeeRatioInBps
                        > settingsStorage.maxRoyaltyFeeRatioInBps + protocolRoyaltyFeeRatioInBps
            ) revert RoyaltyFeeRatioOutOfRange();
        }

        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            if (createContinuousDaoParam.startRound < settingsStorage.drb.currentRound()) {
                revert StartRoundAlreadyPassed();
            }
            daoInfo.startRound = createContinuousDaoParam.startRound;
            daoInfo.mintableRound = createContinuousDaoParam.mintableRound;
            daoInfo.nftMaxSupply = settingsStorage.nftMaxSupplies[createContinuousDaoParam.nftMaxSupplyRank];
            daoInfo.daoUri = createContinuousDaoParam.daoUri;
            daoInfo.royaltyFeeRatioInBps = createContinuousDaoParam.royaltyFeeRatioInBps;
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
            // subdao does not need initTokenSupplyRatio, but we reserve this variable
            // daoInfo.tokenMaxSupply =
            //     (settingsStorage.tokenMaxSupply * createContinuousDaoParam.initTokenSupplyRatio) / BASIS_POINT;

            if (createContinuousDaoParam.daoFloorPriceRank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[daoId] =
                    settingsStorage.daoFloorPrices[createContinuousDaoParam.daoFloorPriceRank];
            }

            daoInfo.daoExist = true;
            emit NewProjectForFunding(
                daoId,
                createContinuousDaoParam.daoUri,
                daoFeePool,
                daoInfo.token,
                daoInfo.nft,
                createContinuousDaoParam.royaltyFeeRatioInBps
            );
        }
    }

    function _createDaoAssetPool(bytes32 daoId, uint256 daoIndex) internal returns (address) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        address daoAssetPool = settingsStorage.feePoolFactory.createD4AFeePool(
            string(abi.encodePacked("Dao Asset Pool for ProtoDao Project ", LibString.toString(daoIndex)))
        ); //this feepool is dao asset pool for reward
        basicDaoInfo.daoAssetPool = daoAssetPool;
        return daoAssetPool;
    }

    function _createFundingPool(bytes32 daoId, uint256 daoIndex) internal returns (address) {
        // SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        // BasicDaoStorage.BasicDaoInfo storage basicDaoInfo = BasicDaoStorage.layout().basicDaoInfos[daoId];
        return address(0);
    }

    // ========================== optimized code =========================
    function _config(address protocol, CreateProjectLocalVars memory vars, bool isBasicDao) internal {
        emit CreateProjectParamEmittedForFunding(
            vars.daoId,
            vars.daoFeePool,
            vars.token,
            vars.nft,
            vars.daoMetadataParam,
            vars.whitelist,
            vars.blacklist,
            vars.daoMintCapParam,
            //vars.splitRatioParam,
            vars.templateParam,
            vars.basicDaoParam,
            vars.actionType,
            vars.allRatioForFundingParam
        );

        bytes32 daoId = vars.daoId;
        ID4ASettingsReadable(protocol).permissionControl().addPermission(daoId, vars.whitelist, vars.blacklist);

        SetMintCapAndPermissionParam memory permissionVars;
        permissionVars.daoId = daoId;
        permissionVars.daoMintCap = vars.daoMintCapParam.daoMintCap;
        permissionVars.userMintCapParams = vars.daoMintCapParam.userMintCapParams;

        // * sort
        if (isBasicDao) {
            NftMinterCapInfo[] memory nftMinterCapInfo;
            nftMinterCapInfo = new NftMinterCapInfo[](1);
            nftMinterCapInfo[0] = NftMinterCapInfo({ nftAddress: vars.nft, nftMintCap: 5 });
            permissionVars.nftMinterCapInfo = nftMinterCapInfo;
        }

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

        IPDProtocolSetter(protocol).setRatioForFunding(daoId, vars.allRatioForFundingParam);

        // setup template
        ID4AProtocolSetter(protocol).setTemplate(daoId, vars.templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(protocol).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(protocol).tradeProtocolFeeRatio();

        address splitter = settingsStorage.royaltySplitterFactory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(protocol).protocolFeePool(),
            protocolRoyaltyFeeRatioInBps,
            vars.daoFeePool,
            uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
        );
        settingsStorage.royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(settingsStorage.royaltySplitterOwner);
        ID4AERC721(vars.nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }
}

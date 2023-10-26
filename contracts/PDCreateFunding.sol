// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { IPDCreateFunding } from "./interface/IPDCreateFunding.sol";
import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
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
    BasicDaoParam
} from "contracts/interface/D4AStructs.sol";
import {
    ZeroFloorPriceCannotUseLinearPriceVariation,
    NotBasicDaoOwner,
    ZeroNftReserveNumber
} from "contracts/interface/D4AErrors.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

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
    uint256 actionType;
    bool needMintableWork;
    uint256 dailyMintCap;
}

contract PDCreateFunding is IPDCreateFunding {
    address public immutable WETH;

    constructor(address WETH_) {
        WETH = WETH_;
    }

    /**
     * @dev create basic dao
     * @param daoMetadataParam metadata param for dao
     * @param whitelist the whitelist
     * @param blacklist the blacklist
     * @param daoMintCapParam the mint cap param for dao
     * @param splitRatioParam the split ratio param
     * @param templateParam the template param
     * @param basicDaoParam the param for basic dao
     * @param actionType the type of action
     */

    function createBasicDao(
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist memory whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        uint256 actionType
    )
        public
        payable
        override
        returns (bytes32 daoId)
    {
        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) {
            revert ZeroFloorPriceCannotUseLinearPriceVariation();
        }

        address protocol = address(this); // gas saving

        daoId = IPDCreate(protocol).createBasicDao{ value: msg.value }(daoMetadataParam, basicDaoParam);

        CreateProjectLocalVars memory vars;

        vars.daoFeePool = ID4AProtocolReadable(protocol).getDaoFeePool(daoId);
        vars.token = ID4AProtocolReadable(protocol).getDaoToken(daoId);
        vars.nft = ID4AProtocolReadable(protocol).getDaoNft(daoId);

        emit CreateProjectParamEmitted(
            daoId,
            vars.daoFeePool,
            vars.token,
            vars.nft,
            daoMetadataParam,
            whitelist,
            blacklist,
            daoMintCapParam,
            splitRatioParam,
            templateParam,
            basicDaoParam,
            actionType
        );

        vars.dailyMintCap = ID4AProtocolReadable(protocol).getDaoDailyMintCap(daoId);
        bool _unifiedPriceModeOff = ID4AProtocolReadable(protocol).getDaoUnifiedPriceModeOff(daoId);
        uint256 _unifiedPrice = ID4AProtocolReadable(protocol).getDaoUnifiedPrice(daoId);
        uint256 _reserveNftNumber = ID4AProtocolReadable(protocol).getDaoReserveNftNumber(daoId);

        emit CreateContinuousProjectParamEmitted(
            daoId, daoId, vars.dailyMintCap, true, _unifiedPriceModeOff, _unifiedPrice, _reserveNftNumber
        );

        ID4ASettingsReadable(protocol).permissionControl().addPermission(daoId, whitelist, blacklist);

        SetMintCapAndPermissionParam memory permissionVars;
        permissionVars.daoId = daoId;
        permissionVars.daoMintCap = daoMintCapParam.daoMintCap;
        permissionVars.userMintCapParams = daoMintCapParam.userMintCapParams;
        //把新建nft放到有铸造上限白名单里并设置cap为5
        NftMinterCapInfo[] memory nftMinterCapInfo = new NftMinterCapInfo[](1);
        nftMinterCapInfo[0] = NftMinterCapInfo({ nftAddress: vars.nft, nftMintCap: 5 });
        permissionVars.nftMinterCapInfo = nftMinterCapInfo;
        permissionVars.whitelist = whitelist;
        permissionVars.blacklist = blacklist;
        permissionVars.unblacklist = Blacklist(new address[](0), new address[](0));
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
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if ((actionType & 0x8) != 0) {
            l.d4aswapFactory.createPair(vars.token, WETH);
        }

        SetRatioParam memory ratioVars;
        ratioVars.daoId = daoId;
        ratioVars.daoCreatorERC20Ratio = splitRatioParam.daoCreatorERC20Ratio;
        ratioVars.canvasCreatorERC20Ratio = splitRatioParam.canvasCreatorERC20Ratio;
        ratioVars.nftMinterERC20Ratio = splitRatioParam.nftMinterERC20Ratio;
        ratioVars.daoFeePoolETHRatio = splitRatioParam.daoFeePoolETHRatio;
        ratioVars.daoFeePoolETHRatioFlatPrice = splitRatioParam.daoFeePoolETHRatioFlatPrice;
        if ((actionType & 0x10) != 0) {
            ID4AProtocolSetter(protocol).setRatio(
                ratioVars.daoId,
                ratioVars.daoCreatorERC20Ratio,
                ratioVars.canvasCreatorERC20Ratio,
                ratioVars.nftMinterERC20Ratio,
                ratioVars.daoFeePoolETHRatio,
                ratioVars.daoFeePoolETHRatioFlatPrice
            );
        }

        // setup template
        ID4AProtocolSetter(protocol).setTemplate(daoId, templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(protocol).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(protocol).tradeProtocolFeeRatio();

        ID4ASettingsReadable(protocol).ownerProxy().transferOwnership(daoId, msg.sender);
        ID4ASettingsReadable(protocol).ownerProxy().transferOwnership(basicDaoParam.canvasId, msg.sender);
        OwnableUpgradeable(vars.nft).transferOwnership(msg.sender);
        address splitter = l.royaltySplitterFactory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(protocol).protocolFeePool(),
            protocolRoyaltyFeeRatioInBps,
            vars.daoFeePool,
            uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
        );
        l.royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(l.royaltySplitterOwner);
        ID4AERC721(vars.nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }

    /**
     * @dev create continuous dao
     * @param existDaoId basic dao id
     * @param daoMetadataParam metadata param for dao
     * @param whitelist the whitelist
     * @param blacklist the blacklist
     * @param daoMintCapParam the mint cap param for dao
     * @param splitRatioParam the split ratio param
     * @param templateParam the template param
     * @param basicDaoParam the param for basic dao
     * @param continuousDaoParam the param for continuous dao
     * @param actionType the type of action
     */
    function createContinuousDao(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist memory whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        ContinuousDaoParam calldata continuousDaoParam,
        uint256 actionType
    )
        public
        payable
        returns (bytes32 daoId)
    {
        address protocol = address(this);
        if (ID4ASettingsReadable(protocol).ownerProxy().ownerOf(existDaoId) != msg.sender) {
            revert NotBasicDaoOwner();
        }
        CreateProjectLocalVars memory vars;
        vars.existDaoId = existDaoId;
        vars.daoMetadataParam = daoMetadataParam;
        vars.whitelist = whitelist;
        vars.blacklist = blacklist;
        vars.daoMintCapParam = daoMintCapParam;
        vars.splitRatioParam = splitRatioParam;
        vars.templateParam = templateParam;
        vars.basicDaoParam = basicDaoParam;
        vars.actionType = actionType;
        vars.needMintableWork = continuousDaoParam.needMintableWork;
        vars.dailyMintCap = continuousDaoParam.dailyMintCap;

        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) {
            revert ZeroFloorPriceCannotUseLinearPriceVariation();
        }
        if (continuousDaoParam.reserveNftNumber == 0 && continuousDaoParam.needMintableWork) {
            revert ZeroNftReserveNumber(); //要么不开，开了就不能传0
        }

        daoId = IPDCreate(protocol).createContinuousDao{ value: msg.value }(
            existDaoId, daoMetadataParam, basicDaoParam, continuousDaoParam
        );
        vars.daoId = daoId;

        // Use the exist DaoFeePool and DaoToken
        vars.daoFeePool = ID4AProtocolReadable(protocol).getDaoFeePool(existDaoId);
        vars.token = ID4AProtocolReadable(protocol).getDaoToken(existDaoId);
        vars.nft = ID4AProtocolReadable(protocol).getDaoNft(daoId);

        emit CreateProjectParamEmitted(
            vars.daoId,
            vars.daoFeePool,
            vars.token,
            vars.nft,
            vars.daoMetadataParam,
            vars.whitelist,
            vars.blacklist,
            vars.daoMintCapParam,
            vars.splitRatioParam,
            vars.templateParam,
            vars.basicDaoParam,
            vars.actionType
        );

        emit CreateContinuousProjectParamEmitted(
            vars.existDaoId,
            vars.daoId,
            vars.dailyMintCap,
            vars.needMintableWork,
            continuousDaoParam.unifiedPriceModeOff,
            ID4AProtocolReadable(protocol).getDaoUnifiedPrice(daoId),
            continuousDaoParam.reserveNftNumber
        );

        ID4ASettingsReadable(protocol).permissionControl().addPermission(daoId, whitelist, blacklist);

        SetMintCapAndPermissionParam memory permissionVars;
        permissionVars.daoId = daoId;
        permissionVars.daoMintCap = daoMintCapParam.daoMintCap;
        permissionVars.userMintCapParams = daoMintCapParam.userMintCapParams;
        NftMinterCapInfo[] memory nftMinterCapInfo;
        permissionVars.nftMinterCapInfo = nftMinterCapInfo;
        permissionVars.whitelist = whitelist;
        permissionVars.blacklist = blacklist;
        permissionVars.unblacklist = Blacklist(new address[](0), new address[](0));
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
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if ((actionType & 0x8) != 0) {
            l.d4aswapFactory.createPair(vars.token, WETH);
        }

        SetRatioParam memory ratioVars;
        ratioVars.daoId = daoId;
        ratioVars.daoCreatorERC20Ratio = splitRatioParam.daoCreatorERC20Ratio;
        ratioVars.canvasCreatorERC20Ratio = splitRatioParam.canvasCreatorERC20Ratio;
        ratioVars.nftMinterERC20Ratio = splitRatioParam.nftMinterERC20Ratio;
        ratioVars.daoFeePoolETHRatio = splitRatioParam.daoFeePoolETHRatio;
        ratioVars.daoFeePoolETHRatioFlatPrice = splitRatioParam.daoFeePoolETHRatioFlatPrice;
        if ((actionType & 0x10) != 0) {
            ID4AProtocolSetter(protocol).setRatio(
                ratioVars.daoId,
                ratioVars.daoCreatorERC20Ratio,
                ratioVars.canvasCreatorERC20Ratio,
                ratioVars.nftMinterERC20Ratio,
                ratioVars.daoFeePoolETHRatio,
                ratioVars.daoFeePoolETHRatioFlatPrice
            );
        }

        // setup template
        ID4AProtocolSetter(protocol).setTemplate(daoId, templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(protocol).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(protocol).tradeProtocolFeeRatio();
        ID4ASettingsReadable(protocol).ownerProxy().transferOwnership(daoId, msg.sender);
        ID4ASettingsReadable(protocol).ownerProxy().transferOwnership(basicDaoParam.canvasId, msg.sender);
        OwnableUpgradeable(vars.nft).transferOwnership(msg.sender);
        address splitter = l.royaltySplitterFactory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(protocol).protocolFeePool(),
            protocolRoyaltyFeeRatioInBps,
            vars.daoFeePool,
            uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
        );
        l.royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(l.royaltySplitterOwner);
        ID4AERC721(vars.nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }
}

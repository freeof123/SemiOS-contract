// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { ReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";
import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import {
    DaoMetadataParam,
    DaoMintCapParam,
    DaoETHAndERC20SplitRatioParam,
    TemplateParam,
    Whitelist,
    Blacklist,
    BasicDaoParam
} from "contracts/interface/D4AStructs.sol";
import { ZeroFloorPriceCannotUseLinearPriceVariation } from "contracts/interface/D4AErrors.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { ID4ACreate } from "contracts/interface/ID4ACreate.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { ID4AERC721 } from "contracts/interface/ID4AERC721.sol";
import { ID4ARoyaltySplitterFactory } from "contracts/interface/ID4ARoyaltySplitterFactory.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";

contract PDCreateProjectProxy is OwnableUpgradeable, ReentrancyGuard {
    address public protocol;
    ID4ARoyaltySplitterFactory public royaltySplitterFactory;
    address public royaltySplitterOwner;
    mapping(bytes32 daoId => address royaltySplitter) public royaltySplitters;

    IUniswapV2Factory public d4aswapFactory;
    address public immutable WETH;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address WETH_) {
        WETH = WETH_;
        _disableInitializers();
    }

    function initialize(
        address d4aswapFactory_,
        address protocol_,
        address royaltySplitterFactory_,
        address royaltySplitterOwner_
    )
        external
        initializer
    {
        __Ownable_init();
        d4aswapFactory = IUniswapV2Factory(d4aswapFactory_);
        protocol = protocol_;
        royaltySplitterFactory = ID4ARoyaltySplitterFactory(royaltySplitterFactory_);
        royaltySplitterOwner = royaltySplitterOwner_;
    }

    function set(
        address newProtocol,
        address newRoyaltySplitterFactory,
        address newRoyaltySplitterOwner,
        address newD4AswapFactory
    )
        public
        onlyOwner
    {
        protocol = newProtocol;
        royaltySplitterFactory = ID4ARoyaltySplitterFactory(newRoyaltySplitterFactory);
        royaltySplitterOwner = newRoyaltySplitterOwner;
        d4aswapFactory = IUniswapV2Factory(newD4AswapFactory);
    }

    event CreateProjectParamEmitted(
        bytes32 daoId,
        address daoFeePool,
        address token,
        address nft,
        DaoMetadataParam daoMetadataParam,
        Whitelist whitelist,
        Blacklist blacklist,
        DaoMintCapParam daoMintCapParam,
        DaoETHAndERC20SplitRatioParam splitRatioParam,
        TemplateParam templateParam,
        BasicDaoParam basicDaoParam,
        uint256 actionType
    );

    event CreateContinuousProjectParamEmitted(
        bytes32 existDaoId, bytes32 daoId, uint256 dailyMintCap, bool needMintableWork
    );

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

    // first bit: 0: project, 1: owner project
    // second bit: 0: without permission, 1: with permission
    // third bit: 0: without mint cap, 1: with mint cap
    // fourth bit: 0: without DEX pair initialized, 1: with DEX pair initialized
    // fifth bit: modify DAO ETH and ERC20 Split Ratio when minting NFTs or not
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
        nonReentrant
        returns (bytes32 daoId)
    {
        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) {
            revert ZeroFloorPriceCannotUseLinearPriceVariation();
        }

        if ((actionType & 0x1) != 0) {
            require(
                IAccessControlUpgradeable(address(protocol)).hasRole(OPERATION_ROLE, msg.sender),
                "only admin can specify project index"
            );
            daoId = IPDCreate(protocol).createOwnerBasicDao{ value: msg.value }(daoMetadataParam, basicDaoParam);
        } else {
            daoId = IPDCreate(protocol).createBasicDao{ value: msg.value }(daoMetadataParam, basicDaoParam);
        }

        CreateProjectLocalVars memory vars;
        vars.daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);
        vars.token = ID4AProtocolReadable(address(protocol)).getDaoToken(daoId);
        vars.nft = ID4AProtocolReadable(address(protocol)).getDaoNft(daoId);
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

        address[] memory minterNFTHolderPasses = new address[](1);
        minterNFTHolderPasses[0] = vars.nft;
        whitelist.minterNFTHolderPasses = minterNFTHolderPasses;
        ID4ASettingsReadable(address(protocol)).permissionControl().addPermission(daoId, whitelist, blacklist);

        if ((actionType & 0x4) != 0) {
            ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
                daoId,
                daoMintCapParam.daoMintCap,
                daoMintCapParam.userMintCapParams,
                whitelist,
                blacklist,
                Blacklist(new address[](0), new address[](0))
            );
        }

        if ((actionType & 0x8) != 0) {
            d4aswapFactory.createPair(vars.token, WETH);
        }

        if ((actionType & 0x10) != 0) {
            ID4AProtocolSetter(address(protocol)).setRatio(
                daoId,
                splitRatioParam.daoCreatorERC20Ratio,
                splitRatioParam.canvasCreatorERC20Ratio,
                splitRatioParam.nftMinterERC20Ratio,
                splitRatioParam.daoFeePoolETHRatio,
                splitRatioParam.daoFeePoolETHRatioFlatPrice
            );
        }

        // setup template
        ID4AProtocolSetter(address(protocol)).setTemplate(daoId, templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(address(protocol)).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(address(protocol)).tradeProtocolFeeRatio();
        ID4ASettingsReadable(address(protocol)).ownerProxy().transferOwnership(daoId, msg.sender);
        ID4ASettingsReadable(address(protocol)).ownerProxy().transferOwnership(basicDaoParam.canvasId, msg.sender);
        OwnableUpgradeable(vars.nft).transferOwnership(msg.sender);
        address splitter = royaltySplitterFactory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(address(protocol)).protocolFeePool(),
            protocolRoyaltyFeeRatioInBps,
            vars.daoFeePool,
            uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
        );
        royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(royaltySplitterOwner);
        ID4AERC721(vars.nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }

    function createContinuousDao(
        bytes32 existDaoId,
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist memory whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        TemplateParam calldata templateParam,
        BasicDaoParam calldata basicDaoParam,
        uint256 actionType,
        bool needMintableWork,
        uint256 dailyMintCap
    )
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
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
        vars.needMintableWork = needMintableWork;
        vars.dailyMintCap = dailyMintCap;

        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) {
            revert ZeroFloorPriceCannotUseLinearPriceVariation();
        }

        // if ((actionType & 0x1) != 0) {
        //     require(
        //         IAccessControlUpgradeable(address(protocol)).hasRole(OPERATION_ROLE, msg.sender),
        //         "only admin can specify project index"
        //     );
        //     daoId = IPDCreate(protocol).createOwnerBasicDao{ value: msg.value }(daoMetadataParam, basicDaoParam);
        // } else {
        //     daoId = IPDCreate(protocol).createBasicDao{ value: msg.value }(daoMetadataParam, basicDaoParam);
        // }
        daoId = IPDCreate(protocol).createContinuousDao{ value: msg.value }(
            existDaoId, daoMetadataParam, basicDaoParam, needMintableWork, dailyMintCap
        ); //这个地方需要加上dailyMintCap
        vars.daoId = daoId;

        // Use the exist DaoFeePool and DaoToken
        vars.daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(existDaoId);
        vars.token = ID4AProtocolReadable(address(protocol)).getDaoToken(existDaoId);
        vars.nft = ID4AProtocolReadable(address(protocol)).getDaoNft(daoId);

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

        emit CreateContinuousProjectParamEmitted(vars.existDaoId, vars.daoId, vars.dailyMintCap, vars.needMintableWork);

        address[] memory minterNFTHolderPasses = new address[](1);
        minterNFTHolderPasses[0] = vars.nft;
        whitelist.minterNFTHolderPasses = minterNFTHolderPasses;
        ID4ASettingsReadable(address(protocol)).permissionControl().addPermission(daoId, whitelist, blacklist);

        if ((actionType & 0x4) != 0) {
            ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
                daoId,
                daoMintCapParam.daoMintCap,
                daoMintCapParam.userMintCapParams,
                vars.whitelist,
                vars.blacklist,
                Blacklist(new address[](0), new address[](0))
            );
        }

        if ((actionType & 0x8) != 0) {
            d4aswapFactory.createPair(vars.token, WETH);
        }

        if ((actionType & 0x10) != 0) {
            ID4AProtocolSetter(address(protocol)).setRatio(
                daoId,
                splitRatioParam.daoCreatorERC20Ratio,
                splitRatioParam.canvasCreatorERC20Ratio,
                splitRatioParam.nftMinterERC20Ratio,
                splitRatioParam.daoFeePoolETHRatio,
                splitRatioParam.daoFeePoolETHRatioFlatPrice
            );
        }

        // setup template
        ID4AProtocolSetter(address(protocol)).setTemplate(daoId, templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(address(protocol)).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(address(protocol)).tradeProtocolFeeRatio();
        ID4ASettingsReadable(address(protocol)).ownerProxy().transferOwnership(daoId, msg.sender);
        ID4ASettingsReadable(address(protocol)).ownerProxy().transferOwnership(basicDaoParam.canvasId, msg.sender);
        OwnableUpgradeable(vars.nft).transferOwnership(msg.sender);
        address splitter = royaltySplitterFactory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(address(protocol)).protocolFeePool(),
            protocolRoyaltyFeeRatioInBps,
            vars.daoFeePool,
            uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
        );
        royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(royaltySplitterOwner);
        ID4AERC721(vars.nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }

    event CreateProjectParamEmitted(
        bytes32 daoId,
        address daoFeePool,
        address token,
        address nft,
        DaoMetadataParam daoMetadataParam,
        Whitelist whitelist,
        Blacklist blacklist,
        DaoMintCapParam daoMintCapParam,
        DaoETHAndERC20SplitRatioParam splitRatioParam,
        TemplateParam templateParam,
        uint256 actionType
    );

    // first bit: 0: project, 1: owner project
    // second bit: 0: without permission, 1: with permission
    // third bit: 0: without mint cap, 1: with mint cap
    // fourth bit: 0: without DEX pair initialized, 1: with DEX pair initialized
    // fifth bit: modify DAO ETH and ERC20 Split Ratio when minting NFTs or not
    function createProject(
        DaoMetadataParam calldata daoMetadataParam,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        DaoMintCapParam calldata daoMintCapParam,
        DaoETHAndERC20SplitRatioParam calldata splitRatioParam,
        TemplateParam calldata templateParam,
        uint256 actionType
    )
        public
        payable
        returns (bytes32 daoId)
    {
        // floor price rank 9999 means 0 floor price, 0 floor price can only use exponential price variation
        if (
            daoMetadataParam.floorPriceRank == 9999
                && templateParam.priceTemplateType != PriceTemplateType.EXPONENTIAL_PRICE_VARIATION
        ) {
            revert ZeroFloorPriceCannotUseLinearPriceVariation();
        }
        if ((actionType & 0x1) != 0) {
            require(
                IAccessControlUpgradeable(address(protocol)).hasRole(OPERATION_ROLE, msg.sender),
                "only admin can specify project index"
            );
            daoId = ID4ACreate(protocol).createOwnerProject{ value: msg.value }(daoMetadataParam);
        } else {
            daoId = ID4ACreate(protocol).createProject{ value: msg.value }(
                daoMetadataParam.startDrb,
                daoMetadataParam.mintableRounds,
                daoMetadataParam.floorPriceRank,
                daoMetadataParam.maxNftRank,
                daoMetadataParam.royaltyFee,
                daoMetadataParam.projectUri
            );
        }

        address daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);
        address token = ID4AProtocolReadable(address(protocol)).getDaoToken(daoId);
        address nft = ID4AProtocolReadable(address(protocol)).getDaoNft(daoId);
        emit CreateProjectParamEmitted(
            daoId,
            daoFeePool,
            token,
            nft,
            daoMetadataParam,
            whitelist,
            blacklist,
            daoMintCapParam,
            splitRatioParam,
            templateParam,
            actionType
        );

        if ((actionType & 0x2) != 0) {
            ID4ASettingsReadable(address(protocol)).permissionControl().addPermission(daoId, whitelist, blacklist);
        }

        if ((actionType & 0x4) != 0) {
            ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
                daoId,
                daoMintCapParam.daoMintCap,
                daoMintCapParam.userMintCapParams,
                whitelist,
                blacklist,
                Blacklist(new address[](0), new address[](0))
            );
        }

        if ((actionType & 0x8) != 0) {
            d4aswapFactory.createPair(token, WETH);
        }

        if ((actionType & 0x10) != 0) {
            ID4AProtocolSetter(address(protocol)).setRatio(
                daoId,
                splitRatioParam.daoCreatorERC20Ratio,
                splitRatioParam.canvasCreatorERC20Ratio,
                splitRatioParam.nftMinterERC20Ratio,
                splitRatioParam.daoFeePoolETHRatio,
                splitRatioParam.daoFeePoolETHRatioFlatPrice
            );
        }

        // setup template
        ID4AProtocolSetter(address(protocol)).setTemplate(daoId, templateParam);

        uint96 royaltyFeeRatioInBps = ID4AProtocolReadable(address(protocol)).getDaoNftRoyaltyFeeRatioInBps(daoId);
        uint256 protocolRoyaltyFeeRatioInBps = ID4ASettingsReadable(address(protocol)).tradeProtocolFeeRatio();
        ID4ASettingsReadable(address(protocol)).ownerProxy().transferOwnership(daoId, msg.sender);
        OwnableUpgradeable(nft).transferOwnership(msg.sender);
        address splitter = royaltySplitterFactory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(address(protocol)).protocolFeePool(),
            protocolRoyaltyFeeRatioInBps,
            daoFeePool,
            uint256(royaltyFeeRatioInBps) - protocolRoyaltyFeeRatioInBps
        );
        royaltySplitters[daoId] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(royaltySplitterOwner);
        ID4AERC721(nft).setRoyaltyInfo(splitter, royaltyFeeRatioInBps);
    }

    receive() external payable { }
}

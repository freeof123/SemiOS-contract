// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import {
    DaoMetadataParam,
    DaoMintCapParam,
    UserMintCapParam,
    DaoETHAndERC20SplitRatioParam,
    TemplateParam,
    Whitelist,
    Blacklist
} from "contracts/interface/D4AStructs.sol";
import { ZeroFloorPriceCannotUseLinearPriceVariation } from "contracts/interface/D4AErrors.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import { ID4AProtocolReadable } from "../interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "../interface/ID4AProtocolSetter.sol";
import { ID4AProtocol } from "../interface/ID4AProtocol.sol";
import { ID4AERC721 } from "../interface/ID4AERC721.sol";
import { ID4ARoyaltySplitterFactory } from "../interface/ID4ARoyaltySplitterFactory.sol";
import { IPermissionControl } from "../interface/IPermissionControl.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";

import { D4ASettings } from "contracts/D4ASettings/D4ASettings.sol";

contract D4ACreateProjectProxy is OwnableUpgradeable {
    ID4AProtocol public protocol;
    ID4ARoyaltySplitterFactory public splitter_factory;
    address public splitter_owner;
    mapping(bytes32 daoId => address royaltySplitter) internal _royaltySplitters;

    IUniswapV2Factory public uniswapV2Factory;
    address public immutable WETH;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address WETH_) {
        WETH = WETH_;
        _disableInitializers();
    }

    function initialize(
        address uniswapV2Factory_,
        address protocol_,
        address splitterFactory_,
        address splitterOwner_
    )
        external
        initializer
    {
        __Ownable_init();
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Factory_);
        protocol = ID4AProtocol(protocol_);
        splitter_factory = ID4ARoyaltySplitterFactory(splitterFactory_);
        splitter_owner = splitterOwner_;
    }

    function set(
        address newProtocol,
        address newSplitterFactory,
        address newSplitterOwner,
        address newUniswapV2Factory
    )
        public
        onlyOwner
    {
        protocol = ID4AProtocol(newProtocol);
        splitter_factory = ID4ARoyaltySplitterFactory(newSplitterFactory);
        splitter_owner = newSplitterOwner;
        uniswapV2Factory = IUniswapV2Factory(newUniswapV2Factory);
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
        returns (bytes32 projectId)
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
            projectId = protocol.createOwnerProject{ value: msg.value }(daoMetadataParam);
        } else {
            projectId = protocol.createProject{ value: msg.value }(
                daoMetadataParam.startDrb,
                daoMetadataParam.mintableRounds,
                daoMetadataParam.floorPriceRank,
                daoMetadataParam.maxNftRank,
                daoMetadataParam.royaltyFee,
                daoMetadataParam.projectUri
            );
        }

        if ((actionType & 0x2) != 0) {
            _addPermission(projectId, whitelist, blacklist);
        }

        if ((actionType & 0x4) != 0) {
            _setMintCapAndPermission(
                projectId,
                daoMintCapParam.daoMintCap,
                daoMintCapParam.userMintCapParams,
                whitelist,
                blacklist,
                Blacklist(new address[](0), new address[](0))
            );
        }

        if ((actionType & 0x8) != 0) {
            (address erc20Token,) = ID4AProtocolReadable(address(protocol)).getProjectTokens(projectId);
            uniswapV2Factory.createPair(erc20Token, WETH);
        }

        if ((actionType & 0x10) != 0) {
            ID4AProtocolSetter(address(protocol)).setRatio(
                projectId,
                splitRatioParam.daoCreatorERC20Ratio,
                splitRatioParam.canvasCreatorERC20Ratio,
                splitRatioParam.nftMinterERC20Ratio,
                splitRatioParam.daoFeePoolETHRatio,
                splitRatioParam.daoFeePoolETHRatioFlatPrice
            );
        }

        // setup template
        ID4AProtocolSetter(address(protocol)).setTemplate(projectId, templateParam);

        _createSplitter(projectId);

        emit CreateProjectParamEmitted(
            projectId,
            getProjectFeePool(projectId),
            getProjectERC20(projectId),
            getProjectERC721(projectId),
            daoMetadataParam,
            whitelist,
            blacklist,
            daoMintCapParam,
            splitRatioParam,
            templateParam,
            actionType
        );
    }

    function _setMintCapAndPermission(
        bytes32 project_id,
        uint32 mintCap,
        UserMintCapParam[] calldata userMintCapParams,
        Whitelist calldata whitelist,
        Blacklist calldata blacklist,
        Blacklist memory unblacklist
    )
        internal
    {
        ID4AProtocolSetter(address(protocol)).setMintCapAndPermission(
            project_id, mintCap, userMintCapParams, whitelist, blacklist, unblacklist
        );
    }

    function _addPermission(bytes32 project_id, Whitelist calldata whitelist, Blacklist calldata blacklist) internal {
        ID4ASettingsReadable(address(protocol)).permissionControl().addPermission(project_id, whitelist, blacklist);
    }

    function _createSplitter(bytes32 project_id) internal returns (address splitter) {
        uint256 rf = 0;
        address erc721_token;

        uint96 royalty_fee;
        {
            (royalty_fee, erc721_token) = getInfo(project_id);
            ID4ASettingsReadable(address(protocol)).ownerProxy().transferOwnership(project_id, msg.sender);
            OwnableUpgradeable(erc721_token).transferOwnership(msg.sender);
            rf = uint256(royalty_fee) - ID4ASettingsReadable(address(protocol)).mintProtocolFeeRatio();
        }
        splitter = splitter_factory.createD4ARoyaltySplitter(
            ID4ASettingsReadable(address(protocol)).protocolFeePool(),
            ID4ASettingsReadable(address(protocol)).tradeProtocolFeeRatio(),
            getProjectFeePool(project_id),
            rf
        );
        _royaltySplitters[project_id] = splitter;
        OwnableUpgradeable(splitter).transferOwnership(splitter_owner);
        ID4AERC721(erc721_token).setRoyaltyInfo(splitter, royalty_fee);
    }

    function getInfo(bytes32 project_id) internal view returns (uint96 royalty_fee, address erc721_token) {
        royalty_fee = getProjectRoyaltyFee(project_id);
        erc721_token = getProjectERC721(project_id);
    }

    function getProjectRoyaltyFee(bytes32 project_id) internal view returns (uint96) {
        (,,,, uint96 royalty_fee,,,) = ID4AProtocolReadable(address(protocol)).getProjectInfo(project_id);
        return royalty_fee;
    }

    function getProjectFeePool(bytes32 project_id) internal view returns (address) {
        (,,, address fee_pool,,,,) = ID4AProtocolReadable(address(protocol)).getProjectInfo(project_id);
        return fee_pool;
    }

    function getProjectERC20(bytes32 daoId) internal view returns (address) {
        (address erc20_token,) = ID4AProtocolReadable(address(protocol)).getProjectTokens(daoId);
        return erc20_token;
    }

    function getProjectERC721(bytes32 project_id) internal view returns (address) {
        (, address erc721_token) = ID4AProtocolReadable(address(protocol)).getProjectTokens(project_id);
        return erc721_token;
    }

    function getSplitterAddress(bytes32 project_id) public view returns (address) {
        return _royaltySplitters[project_id];
    }

    receive() external payable { }
}

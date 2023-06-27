// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DaoMetadataParam, UserMintCapParam, TemplateParam } from "./D4AStructs.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";

interface ID4AProtocol {
    function createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 maxNftRank,
        uint96 royaltyFeeInBps,
        string memory daoUri
    )
        external
        payable
        returns (bytes32 daoId);

    function createOwnerProject(DaoMetadataParam calldata daoMetadata) external payable returns (bytes32 daoId);

    function claimProjectERC20Reward(bytes32 daoId) external returns (uint256);

    function claimCanvasReward(bytes32 canvasId) external returns (uint256);

    function claimNftMinterReward(bytes32 daoId, address minter) external returns (uint256);

    function exchangeERC20ToETH(bytes32 daoId, uint256 amount, address to) external returns (uint256);

    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        external;

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) external;

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        IPermissionControl.Whitelist memory whitelist,
        IPermissionControl.Blacklist memory blacklist,
        IPermissionControl.Blacklist memory unblacklist
    )
        external;

    function getProjectCanvasAt(bytes32 _project_id, uint256 _index) external view returns (bytes32);

    function getProjectInfo(bytes32 _project_id)
        external
        view
        returns (
            uint256 start_prb,
            uint256 mintable_rounds,
            uint256 max_nft_amount,
            address fee_pool,
            uint96 royalty_fee,
            uint256 index,
            string memory uri,
            uint256 erc20_total_supply
        );

    function getProjectFloorPrice(bytes32 _project_id) external view returns (uint256);

    function getProjectTokens(bytes32 _project_id) external view returns (address erc20_token, address erc721_token);

    function getCanvasNFTCount(bytes32 _canvas_id) external view returns (uint256);

    function getTokenIDAt(bytes32 _canvas_id, uint256 _index) external view returns (uint256);

    function getCanvasProject(bytes32 _canvas_id) external view returns (bytes32);

    function getCanvasIndex(bytes32 _canvas_id) external view returns (uint256);

    function getCanvasURI(bytes32 _canvas_id) external view returns (string memory);

    function getCanvasLastPrice(bytes32 canvasId) external view returns (uint256 round, uint256 price);

    function getCanvasNextPrice(bytes32 canvasId) external view returns (uint256);

    function getCanvasCreatorERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getNftMinterERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) external view returns (uint256);
}

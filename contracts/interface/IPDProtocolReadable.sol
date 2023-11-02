// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ID4AProtocolReadable } from "./ID4AProtocolReadable.sol";

interface IPDProtocolReadable is ID4AProtocolReadable {
    // protocol related functions
    function getNFTTokenCanvas(bytes32 daoId, uint256 tokenId) external view returns (bytes32);

    function getLastestDaoIndex(uint8 daoTag) external view returns (uint256);

    function getDaoId(uint8 daoTag, uint256 daoIndex) external view returns (bytes32);

    function getDaoAncestor(bytes32 daoId) external view returns (bytes32);
    //1.3 add ----------------------------------

    function getDaoVersion(bytes32 daoId) external view returns (uint8);
    function getCanvasCreatorMintFeeRatio(bytes32 daoId) external returns (uint256);
    function getAssetPoolMintFeeRatio(bytes32 daoId) external returns (uint256);
    function getRedeemPoolMintFeeRatio(bytes32 daoId) external returns (uint256);
    function getCanvasCreatorMintFeeRatioFiatPrice(bytes32 daoId) external returns (uint256);
    function getAssetPoolMintFeeRatioFiatPrice(bytes32 daoId) external view returns (uint256);
    function getRedeemPoolMintFeeRatioFiatPrice(bytes32 daoId) external view returns (uint256);
    function getMinterERC20RewardRatio(bytes32 daoId) external view returns (uint256);
    function getCanvasCreatorERC20RewardRatio(bytes32 daoId) external view returns (uint256);
    function getDaoCreatorERC20RewardRatio(bytes32 daoId) external view returns (uint256);
    function getMinterETHRewardRatio(bytes32 daoId) external view returns (uint256);
    function getCanvasCreatorETHRewardRatio(bytes32 daoId) external view returns (uint256);
    function getDaoCreatorETHRewardRatio(bytes32 daoId) external view returns (uint256);
}

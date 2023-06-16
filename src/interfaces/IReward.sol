// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IReward {
    function getReward(bytes32 canvasId) external view returns (uint256 reward);

    function updateReward(bytes32 canvasId) external returns (uint256 reward);
}

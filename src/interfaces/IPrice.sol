// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPrice {
    function getNextMintPrice(bytes32 canvasId) external view returns (uint256 price);

    function updateMintPrice(bytes32 canvasId) external returns (uint256 price);
}

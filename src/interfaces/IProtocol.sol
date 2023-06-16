// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IProtocol {
    function createDao() external returns (bytes32 daoId);

    function createCanvas() external returns (bytes32 canvasId);

    function mintNft() external returns (uint256 nftId);

    function batchMintNft() external returns (uint256[] memory nftId);
}

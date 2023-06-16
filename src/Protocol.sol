// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IProtocol } from "./interfaces/IProtocol.sol";

contract Protocol is IProtocol {
    string public constant NAME = "DAO For Art";
    string public constant VERSION = "2.0.0";

    function createDao() external override returns (bytes32 daoId) { }

    function createCanvas() external override returns (bytes32 canvasId) { }

    function mintNft() external override returns (uint256 nftId) { }

    function batchMintNft() external override returns (uint256[] memory nftId) { }
}

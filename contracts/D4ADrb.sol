// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ID4ADrb } from "./interface/ID4ADrb.sol";

contract D4ADrb is ID4ADrb, Ownable {
    struct Checkpoint {
        uint256 startDrb;
        uint256 startBlock;
        uint256 blocksPerDrbE18;
    }

    Checkpoint[] public checkpoints;

    constructor(uint256 startBlock, uint256 blocksPerDrbE18) {
        checkpoints.push(Checkpoint({ startDrb: 0, startBlock: startBlock, blocksPerDrbE18: blocksPerDrbE18 }));
        emit CheckpointSet(0, startBlock, blocksPerDrbE18);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getCheckpointsLength() public view returns (uint256) {
        return checkpoints.length;
    }

    function getStartBlock(uint256 drb) public view returns (uint256) {
        uint256 index = checkpoints.length - 1;
        while (checkpoints[index].startDrb > drb) {
            --index;
        }
        return ((drb - checkpoints[index].startDrb) * checkpoints[index].blocksPerDrbE18 / 1e18)
            + checkpoints[index].startBlock;
    }

    function getDrb(uint256 blockNumber) public view returns (uint256) {
        uint256 length = checkpoints.length;
        uint256 index = length - 1;
        while (checkpoints[index].startBlock > blockNumber) {
            --index;
        }

        return length == index + 1
            // new checkpoint not set
            ? ((blockNumber - checkpoints[index].startBlock) * 1e18) / checkpoints[index].blocksPerDrbE18
                + checkpoints[index].startDrb
            // already set new checkpoint
            : _min(
                ((blockNumber - checkpoints[index].startBlock) * 1e18) / checkpoints[index].blocksPerDrbE18
                    + checkpoints[index].startDrb,
                checkpoints[index + 1].startDrb - 1
            );
    }

    function currentRound() public view returns (uint256) {
        return getDrb(block.number);
    }

    function setNewCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) public onlyOwner {
        checkpoints.push(Checkpoint({ startDrb: startDrb, startBlock: startBlock, blocksPerDrbE18: blocksPerDrbE18 }));
        emit CheckpointSet(startDrb, startBlock, blocksPerDrbE18);
    }

    function modifyLastCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) public onlyOwner {
        checkpoints[checkpoints.length - 1] =
            Checkpoint({ startDrb: startDrb, startBlock: startBlock, blocksPerDrbE18: blocksPerDrbE18 });
        emit CheckpointSet(startDrb, startBlock, blocksPerDrbE18);
    }
}

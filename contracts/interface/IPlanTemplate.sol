// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UpdateRewardParam } from "contracts/interface/D4AStructs.sol";

interface IPlanTemplate {
    function updateReward(bytes32 planId, bytes32 nftHash, bytes memory data) external payable;
    function claimReward(
        bytes32 planId,
        bytes32 nftHash,
        address owner,
        bytes memory data
    )
        external
        returns (uint256);
    function afterUpdate(bytes32 planId, bytes32 nftHash, bytes memory data) external;
}

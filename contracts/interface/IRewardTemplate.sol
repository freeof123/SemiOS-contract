// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UpdateRewardParam, GetRoundRewardParam } from "contracts/interface/D4AStructs.sol";

interface IRewardTemplate {
    function updateReward(UpdateRewardParam memory param) external payable;

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        external
        returns (uint256 protocolClaimableReward, uint256 daoCreatorClaimableReward);

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        external
        returns (uint256 claimableReward);

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        external
        returns (uint256 claimableReward);

    function getRoundReward(GetRoundRewardParam memory param) external pure returns (uint256 rewardAmount);
}

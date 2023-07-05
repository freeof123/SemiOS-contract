// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UpdateRewardParam } from "contracts/interface/D4AStructs.sol";
import { RewardStorage } from "contracts/storages/RewardStorage.sol";

interface IRewardTemplate {
    function updateReward(UpdateRewardParam memory param) external payable;

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 protocolClaimableReward, uint256 daoCreatorClaimableReward);

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 claimableReward);

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 claimableReward);

    function setRewardCheckpoint(
        bytes32 daoId,
        uint256 rewardDecayFactor,
        uint256 rewardDecayLife,
        bool isProgressiveJackpot
    )
        external
        payable;

    function getActiveRoundsOfCheckpoint(
        uint256[] memory activeRounds,
        uint256 startRound,
        uint256 endRound
    )
        external
        pure
        returns (uint256[] memory);

    function getRoundIndex(uint256[] memory activeRounds, uint256 round) external pure returns (uint256 index);

    function getRoundReward(
        bytes32 daoId,
        uint256 round,
        uint256 lastActiveRound
    )
        external
        view
        returns (uint256 rewardAmount);
}

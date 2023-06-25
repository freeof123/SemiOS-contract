// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRewardTemplate {
    function updateReward(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        uint256 daoFeeAmount,
        uint256 daoCreatorERC20RatioInBps
    )
        external;

    function claimDaoCreatorReward(
        bytes32 daoId,
        address daoCreator,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        external;

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        external;

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        address token
    )
        external;

    function getRoundReward(
        uint256 totalReward,
        uint256 startRound,
        uint256 round,
        uint256[] memory activeRounds,
        uint256 totalRound,
        uint256 decayFactor,
        uint256 decayLife,
        bool isProgressiveJackpot
    )
        external
        pure
        returns (uint256 rewardAmount);
}

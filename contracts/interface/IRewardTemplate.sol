// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { GetRoundRewardParam } from "contracts/interface/D4AStructs.sol";

interface IRewardTemplate {
    function updateReward(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 startRound,
        uint256 currentRound,
        uint256 totalRound,
        uint256 daoFeeAmount,
        uint256 protocolERC20RatioInBps,
        uint256 daoCreatorERC20RatioInBps,
        uint256 canvasRebateRatioInBps
    )
        external
        payable;

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
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

    function getRoundReward(GetRoundRewardParam memory param) external pure returns (uint256 rewardAmount);
}

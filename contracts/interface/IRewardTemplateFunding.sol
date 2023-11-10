// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UpdateRewardParamFunding } from "contracts/interface/D4AStructs.sol";

interface IRewardTemplateFunding {
    function updateRewardFunding(UpdateRewardParamFunding memory param) external payable;

    function claimDaoCreatorReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 currentRound,
        address token
    )
        external
        returns (
            uint256 protocolClaimableERC20Reward,
            uint256 daoCreatorClaimableERC20Reward,
            uint256 protocolClaimableETHReward,
            uint256 daoCreatorClaimableETHReward
        );

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 claimableERC20Reward, uint256 claimableETHReward);

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 currentRound,
        address token
    )
        external
        returns (uint256 claimableERC20Reward, uint256 claimableETHReward);
    function getRoundReward(bytes32 daoId, uint256 round, address token) external view returns (uint256 rewardAmount);
}

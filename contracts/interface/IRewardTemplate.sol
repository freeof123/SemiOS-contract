// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UpdateRewardParam, NftIdentifier } from "contracts/interface/D4AStructs.sol";

interface IRewardTemplate {
    event DaoBlockRewardDistributedToChildrenDao(
        bytes32 fromDaoId, bytes32 toDaoId, address token, uint256 amount, uint256 round
    );
    event DaoBlockRewardDistributedToRedeemPool(
        bytes32 fromDaoId, address redeemPool, address token, uint256 amount, uint256 round
    );
    event DaoBlockRewardForSelf(bytes32 daoId, address token, uint256 amount, uint256 round);

    event DaoBlockRewardTotal(bytes32 daoId, address token, uint256 erc20Amount, uint256 ethAmount, uint256 round);

    function updateReward(UpdateRewardParam memory param) external payable;

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
        payable
        returns (uint256 claimableERC20Reward, uint256 claimableETHReward);

    function claimNftTopUpBalance(
        bytes32 daoId,
        NftIdentifier memory nft,
        uint256 currentRound,
        address token
    )
        external
        payable
        returns (uint256 claimableERC20Reward, uint256 claimableETHReward);
    function getRoundReward(bytes32 daoId, uint256 round, address token) external view returns (uint256 rewardAmount);
    function getDaoRoundDistributeAmount(
        bytes32 daoId,
        address token,
        uint256 currentRound,
        uint256 remainingRound
    )
        external
        view
        returns (uint256 distributeAmount);
}

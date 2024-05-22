// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UpdateRewardParam } from "contracts/interface/D4AStructs.sol";

interface IRewardTemplate {
    event DaoBlockRewardDistributedToChildrenDao(
        bytes32 fromDaoId, bytes32 toDaoId, address token, uint256 amount, uint256 round
    );
    event DaoBlockRewardDistributedToRedeemPool(
        bytes32 fromDaoId, address redeemPool, address token, uint256 amount, uint256 round
    );
    event DaoBlockRewardForSelf(bytes32 daoId, address token, uint256 amount, uint256 round);

    event DaoBlockRewardTotal(bytes32 daoId, address token, uint256 outputAmount, uint256 inputAmount, uint256 round);

    event PDTopUpBalanceUpdated(bytes32 daoId, bytes32 nftHash, uint256 outputAmount, uint256 inputAmount);

    function updateReward(UpdateRewardParam memory param) external payable;

    function claimDaoNftOwnerReward(
        bytes32 daoId,
        address protocolFeePool,
        address daoCreator,
        uint256 currentRound,
        address token,
        address inputToken
    )
        external
        returns (
            uint256 protocolClaimableOutputReward,
            uint256 daoCreatorClaimableOutputReward,
            uint256 protocolClaimableInputReward,
            uint256 daoCreatorClaimableInputReward
        );

    function claimCanvasCreatorReward(
        bytes32 daoId,
        bytes32 canvasId,
        address canvasCreator,
        uint256 currentRound,
        address token,
        address inputToken
    )
        external
        returns (uint256 claimableOutputReward, uint256 claimableInputReward);

    function claimNftMinterReward(
        bytes32 daoId,
        address nftMinter,
        uint256 currentRound,
        address token,
        address inputToken
    )
        external
        payable
        returns (uint256 claimableOutputReward, uint256 claimableInputReward);

    function claimNftTopUpBalance(
        bytes32 daoId,
        bytes32 nftHash,
        uint256 currentRound
    )
        external
        payable
        returns (uint256 claimableOutputReward, uint256 claimableInputReward);
    function getRoundReward(bytes32 daoId, uint256 round, bool isInput) external view returns (uint256 rewardAmount);
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

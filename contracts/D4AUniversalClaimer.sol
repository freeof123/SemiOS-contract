// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { IPDProtocol } from "./interface/IPDProtocol.sol";

struct ClaimMultiRewardParam {
    address protocol;
    bytes32[] canvasIds;
    bytes32[] daoIds;
}

contract D4AUniversalClaimer {
    function claimMultiReward(ClaimMultiRewardParam calldata params)
        public
        returns (uint256 outputAmountTotal, uint256 inputAmountTotal)
    {
        for (uint256 i = 0; i < params.canvasIds.length;) {
            (uint256 outputAmount, uint256 inputAmount) =
                IPDProtocol(params.protocol).claimCanvasReward(params.canvasIds[i]);
            outputAmountTotal += outputAmount;
            inputAmountTotal += inputAmount;
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < params.daoIds.length;) {
            (uint256 outputAmount, uint256 inputAmount) =
                IPDProtocol(params.protocol).claimDaoNftOwnerReward(params.daoIds[i]);
            outputAmountTotal += outputAmount;
            outputAmountTotal += inputAmount;
            (outputAmount, inputAmount) =
                IPDProtocol(params.protocol).claimNftMinterReward(params.daoIds[i], msg.sender);
            outputAmountTotal += outputAmount;
            inputAmountTotal += inputAmount;
            unchecked {
                ++i;
            }
        }
    }
}

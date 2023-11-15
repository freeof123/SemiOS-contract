// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";
import { IPDProtocol } from "./interface/IPDProtocol.sol";

struct ClaimMultiRewardParam {
    address protocol;
    bytes32[] canvasIds;
    bytes32[] daoIds;
}

contract D4AUniversalClaimer {
    function claimMultiReward(ClaimMultiRewardParam[] calldata params) public returns (uint256 tokenAmount) {
        for (uint256 i; i < params.length;) {
            for (uint256 j; j < params[i].canvasIds.length;) {
                tokenAmount += ID4AProtocol(params[i].protocol).claimCanvasReward(params[i].canvasIds[j]);
                unchecked {
                    ++j;
                }
            }
            for (uint256 j; j < params[i].daoIds.length;) {
                tokenAmount += ID4AProtocol(params[i].protocol).claimProjectERC20Reward(params[i].daoIds[j]);
                tokenAmount += ID4AProtocol(params[i].protocol).claimNftMinterReward(params[i].daoIds[j], msg.sender);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        return tokenAmount;
    }

    function claimMultiRewardFunding(ClaimMultiRewardParam calldata params)
        public
        returns (uint256 erc20AmountTotal, uint256 ethAmountTotal)
    {
        for (uint256 i = 0; i < params.canvasIds.length;) {
            (uint256 erc20Amount, uint256 ethAmount) =
                IPDProtocol(params.protocol).claimCanvasRewardFunding(params.canvasIds[i]);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < params.daoIds.length;) {
            (uint256 erc20Amount, uint256 ethAmount) =
                IPDProtocol(params.protocol).claimDaoCreatorRewardFunding(params.daoIds[i]);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            (erc20Amount, ethAmount) =
                IPDProtocol(params.protocol).claimNftMinterRewardFunding(params.daoIds[i], msg.sender);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            unchecked {
                ++i;
            }
        }
    }
}
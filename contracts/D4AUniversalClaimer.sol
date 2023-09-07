// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";

contract D4AUniversalClaimer {
    struct ClaimMultiRewardParam {
        address protocol;
        bytes32[] canvasIds;
        bytes32[] daoIds;
    }

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
}

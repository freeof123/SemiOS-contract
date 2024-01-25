// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { ID4AProtocolReadable } from "./interface/ID4AProtocolReadable.sol";
import { ID4AProtocol } from "./interface/ID4AProtocol.sol";
import { IPDProtocol } from "./interface/IPDProtocol.sol";

contract D4AClaimer {
    IPDProtocol protocol;

    constructor(address _protocol) {
        protocol = IPDProtocol(_protocol);
    }

    // function claimMultiReward(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256) {
    //     uint256 amount;
    //     if (canvas.length > 0) {
    //         for (uint256 i = 0; i < canvas.length; i++) {
    //             amount += protocol.claimCanvasReward(canvas[i]);
    //         }
    //     }
    //     if (projects.length > 0) {
    //         for (uint256 i = 0; i < projects.length; i++) {
    //             amount += protocol.claimProjectERC20Reward(projects[i]);
    //             amount += protocol.claimNftMinterReward(projects[i], msg.sender);
    //         }
    //     }
    //     return amount;
    // }

    // function claimMultiRewardWithETH(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256) {
    //     uint256 ethAmount;
    //     for (uint256 i = 0; i < canvas.length;) {
    //         unchecked {
    //             uint256 tokenAmount = protocol.claimCanvasReward(canvas[i]);
    //             ethAmount += protocol.exchangeERC20ToETH(
    //                 ID4AProtocolReadable(address(protocol)).getCanvasDaoId(canvas[i]), tokenAmount, msg.sender
    //             );
    //             ++i;
    //         }
    //     }
    //     for (uint256 i; i < projects.length;) {
    //         unchecked {
    //             uint256 tokenAmount = protocol.claimProjectERC20Reward(projects[i])
    //                 + protocol.claimNftMinterReward(projects[i], msg.sender);
    //             ethAmount += protocol.exchangeERC20ToETH(projects[i], tokenAmount, msg.sender);
    //             ++i;
    //         }
    //     }
    //     return ethAmount;
    // }

    function claimMultiRewardFunding(
        bytes32[] memory canvas,
        bytes32[] memory projects
    )
        public
        returns (uint256 erc20AmountTotal, uint256 ethAmountTotal)
    {
        for (uint256 i = 0; i < canvas.length;) {
            (uint256 erc20Amount, uint256 ethAmount) = protocol.claimCanvasReward(canvas[i]);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < projects.length;) {
            (uint256 erc20Amount, uint256 ethAmount) = protocol.claimDaoNftOwnerReward(projects[i]);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            (erc20Amount, ethAmount) = protocol.claimNftMinterReward(projects[i], msg.sender);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            unchecked {
                ++i;
            }
        }
    }

    function claimMultiRewardWithETHFunding(
        bytes32[] memory canvas,
        bytes32[] memory projects
    )
        public
        returns (uint256 ethAmountTotal)
    {
        for (uint256 i = 0; i < canvas.length;) {
            (uint256 erc20Amount, uint256 ethAmount) = protocol.claimCanvasReward(canvas[i]);
            ethAmountTotal += ethAmount;
            ethAmountTotal += protocol.exchangeERC20ToETH(
                ID4AProtocolReadable(address(protocol)).getCanvasDaoId(canvas[i]), erc20Amount, msg.sender
            );
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < projects.length;) {
            uint256 erc20AmountTotal;
            (uint256 erc20Amount, uint256 ethAmount) = protocol.claimDaoNftOwnerReward(projects[i]);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            (erc20Amount, ethAmount) = protocol.claimNftMinterReward(projects[i], msg.sender);
            erc20AmountTotal += erc20Amount;
            ethAmountTotal += ethAmount;
            ethAmountTotal += protocol.exchangeERC20ToETH(projects[i], erc20AmountTotal, msg.sender);
            unchecked {
                ++i;
            }
        }
    }
}

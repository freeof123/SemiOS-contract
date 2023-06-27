// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./interface/ID4AProtocol.sol";

contract D4AClaimer {
    ID4AProtocol protocol;

    constructor(address _protocol) {
        protocol = ID4AProtocol(_protocol);
    }

    function claimMultiReward(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256) {
        uint256 amount;
        if (canvas.length > 0) {
            for (uint256 i = 0; i < canvas.length; i++) {
                amount += protocol.claimCanvasReward(canvas[i]);
            }
        }
        if (projects.length > 0) {
            for (uint256 i = 0; i < projects.length; i++) {
                amount += protocol.claimProjectERC20Reward(projects[i]);
                amount += protocol.claimNftMinterReward(projects[i], msg.sender);
            }
        }
        return amount;
    }

    function claimMultiRewardWithETH(bytes32[] memory canvas, bytes32[] memory projects) public returns (uint256) {
        uint256 ethAmount;
        for (uint256 i = 0; i < canvas.length;) {
            unchecked {
                uint256 tokenAmount = protocol.claimCanvasReward(canvas[i]);
                ethAmount += protocol.exchangeERC20ToETH(protocol.getCanvasProject(canvas[i]), tokenAmount, msg.sender);
                ++i;
            }
        }
        for (uint256 i; i < projects.length;) {
            unchecked {
                uint256 tokenAmount = protocol.claimProjectERC20Reward(projects[i])
                    + protocol.claimNftMinterReward(projects[i], msg.sender);
                ethAmount += protocol.exchangeERC20ToETH(projects[i], tokenAmount, msg.sender);
                ++i;
            }
        }
        return ethAmount;
    }
}

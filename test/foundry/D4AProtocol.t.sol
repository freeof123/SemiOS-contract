// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "./utils/DeployHelper.sol";
import { MintNftSigUtils } from "./utils/MintNftSigUtils.sol";

contract D4AProtocolTest is DeployHelper {
    MintNftSigUtils public sigUtils;
    bytes32 public daoId;
    IERC20 public token;
    address public daoFeePool;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();

        sigUtils = new MintNftSigUtils(address(protocol));

        startHoax(daoCreator.addr);
        daoId = _createTrivialDao(0, 50, 0, 0, 750, "test dao uri");
        (address temp,) = protocol.getProjectTokens(daoId);
        token = IERC20(temp);
        (,,,, daoFeePool,,,,) = protocol.getProjectInfo(daoId);

        startHoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0));
    }

    function test_setCanvasRebateRatioInBps() public {
        uint256 ratio = 1000;
        startHoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId, ratio);
        assertEq(protocol.getCanvasRebateRatioInBps(canvasId), ratio);
    }

    function test_getCanvasRebateRatioInBps() public {
        assertEq(protocol.getCanvasRebateRatioInBps(canvasId), 0);
        test_setCanvasRebateRatioInBps();
        assertEq(protocol.getCanvasRebateRatioInBps(canvasId), 1000);
    }

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    function test_setCanvasRebateRatioInBps_ExpectEmit() public {
        uint256 ratio = 1000;
        startHoax(canvasCreator.addr);
        vm.expectEmit(address(protocol));
        emit CanvasRebateRatioInBpsSet(canvasId, ratio);
        protocol.setCanvasRebateRatioInBps(canvasId, ratio);
    }

    error NotCanvasOwner();

    function test_RevertIf_setCanvasRebateRatioInBps_NotCanvasOwner() public {
        uint256 ratio = 1000;
        startHoax(randomGuy.addr);
        vm.expectRevert(NotCanvasOwner.selector);
        protocol.setCanvasRebateRatioInBps(canvasId, ratio);
    }
}

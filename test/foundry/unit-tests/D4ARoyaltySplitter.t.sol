// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { ID4ASettingsReadable, TestERC20, DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { D4ARoyaltySplitter } from "contracts/royalty-splitter/D4ARoyaltySplitter.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

contract D4ARoyaltySplitterTest is DeployHelper {
    D4ARoyaltySplitter public splitter;
    address public daoFeePool;
    uint96 public royaltyFee = 750;
    uint256 protocolShare;

    TestERC20 internal _testERC20_1 = new TestERC20();

    function setUp() public {
        setUpEnv();
        protocolShare = ID4ASettingsReadable(address(protocol)).tradeProtocolFeeRatio();

        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 50;
        createDaoParam.isBasicDao = true;
        createDaoParam.noPermission = true;
        createDaoParam.selfRewardRatioERC20 = 10_000;
        createDaoParam.selfRewardRatioETH = 10_000;

        bytes32 daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);
        splitter = D4ARoyaltySplitter(payable(protocol.royaltySplitters(daoId)));

        deal(address(_testERC20), daoCreator.addr, 1e6 ether);
        deal(address(_testERC20_1), daoCreator.addr, 1e6 ether);

        startHoax(daoCreator.addr);
        _testERC20.approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{ value: 1e6 ether }(
            address(_testERC20), 1e6 ether, 0, 0, daoCreator.addr, type(uint256).max
        );
        _testERC20_1.approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{ value: 1e6 ether }(
            address(_testERC20_1), 1e6 ether, 0, 0, daoCreator.addr, type(uint256).max
        );
        SafeTransferLib.safeTransferETH(address(weth), 10 ether);
        IERC20(weth).transfer(address(splitter), 10 ether);
        vm.stopPrank();

        deal(address(_testERC20), address(splitter), 10 ether);
        deal(address(_testERC20_1), address(splitter), 5 ether);
    }

    function test_protocolFeePool() public {
        assertEq(splitter.protocolFeePool(), protocolFeePool.addr);
    }

    function test_daoFeePool() public {
        assertEq(splitter.daoFeePool(), daoFeePool);
    }

    function test_protocolShare() public {
        assertEq(splitter.protocolShare(), protocolShare);
    }

    function test_daoShare() public {
        assertEq(splitter.daoShare(), 1000);
    }

    function test_threshold() public {
        assertEq(splitter.threshold(), 5 ether);
    }

    function test_router() public {
        assertEq(address(splitter.router()), address(uniswapV2Router));
    }

    function test_WETH() public {
        assertEq(splitter.WETH(), address(weth));
    }

    function test_setShare() public {
        hoax(royaltySplitterOwner.addr);
        splitter.setShare(1000, 0);
        assertEq(splitter.protocolShare(), 1000);
        assertEq(splitter.daoShare(), 0);
    }

    function test_setThreshold() public {
        hoax(royaltySplitterOwner.addr);
        splitter.setThreshold(10 ether);
        assertEq(splitter.threshold(), 10 ether);
    }

    function test_setRouter() public {
        hoax(royaltySplitterOwner.addr);
        splitter.setRouter(address(0));
        assertEq(address(splitter.router()), address(0));
    }

    function test_claimERC20() public {
        deal(address(_testERC20), address(splitter), 1e6 ether);
        splitter.claimERC20(address(_testERC20));
        assertEq(_testERC20.balanceOf(protocolFeePool.addr), 200_000 ether);
        assertEq(_testERC20.balanceOf(daoFeePool), 800_000 ether);
        assertEq(_testERC20.balanceOf(address(splitter)), 0);
    }

    function test_splitETH() public {
        SafeTransferLib.safeTransferETH(address(splitter), 10 ether);
        assertEq(protocolFeePool.addr.balance, 2 ether);
        assertEq(daoFeePool.balance, 8 ether);
        assertEq(address(splitter).balance, 0);
    }

    // assertion failed
    function test_splitETH_viaFallback() public {
        (bool succ,) = address(splitter).call{ value: 10 ether }("test");
        require(succ);
        assertEq(protocolFeePool.addr.balance, 2 ether);
        assertEq(daoFeePool.balance, 8 ether);
        assertEq(address(splitter).balance, 0);
    }

    // event ETHTransfered(address indexed to, uint256 amount);

    // function test_splitETH_ExpectEmit() public {
    //     vm.expectEmit(true, true, true, true);
    //     emit ETHTransfered(protocolFeePool.addr, 10 ether * protocolShare / royaltyFee);
    //     vm.expectEmit(true, true, true, true);
    //     emit ETHTransfered(daoFeePool, 10 ether - 10 ether * protocolShare / royaltyFee);
    //     SafeTransferLib.safeTransferETH(address(splitter), 10 ether);
    // }

    function test_checkUpKeep() public {
        deal(address(_testERC20_1), address(splitter), 0);

        address[] memory tokens = new address[](2);
        tokens[0] = address(_testERC20);
        tokens[1] = address(_testERC20_1);
        bytes memory checkData = abi.encode(tokens);
        (bool upKeepNeeded, bytes memory performData) = splitter.checkUpkeep(checkData);
        assertEq(upKeepNeeded, true);
        address[] memory returnTokens = new address[](1);
        returnTokens[0] = address(_testERC20);
        assertEq(performData, abi.encode(IERC20(weth).balanceOf(address(splitter)), returnTokens));
    }

    function test_checkUpKeep_ZeroTokenBalance() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(_testERC20);
        tokens[1] = address(_testERC20_1);
        bytes memory checkData = abi.encode(tokens);
        (bool upKeepNeeded, bytes memory performData) = splitter.checkUpkeep(checkData);
        assertEq(upKeepNeeded, true);
        address[] memory returnTokens = new address[](1);
        returnTokens[0] = address(_testERC20);
        assertEq(performData, abi.encode(IERC20(weth).balanceOf(address(splitter)), returnTokens));
    }

    function test_performUpkeep() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(_testERC20);
        tokens[1] = address(_testERC20_1);
        bytes memory checkData = abi.encode(tokens);
        (, bytes memory performData) = splitter.checkUpkeep(checkData);

        uint256 protocolFee;
        uint256 daoFee;
        {
            address[] memory paths = new address[](2);
            paths[0] = address(_testERC20);
            paths[1] = address(weth);
            uint256 token1ToETHAmount = uniswapV2Router.getAmountsOut(10 ether, paths)[1];
            protocolFee = (10 ether + token1ToETHAmount) * protocolShare / royaltyFee;
            daoFee = (10 ether + token1ToETHAmount) - protocolFee;
        }
        splitter.performUpkeep(performData);
        assertEq(IERC20(weth).balanceOf(address(splitter)), 0);
        assertEq(_testERC20.balanceOf(address(splitter)), 0);
        assertEq(_testERC20_1.balanceOf(address(splitter)), 5 ether);
        assertEq(protocolFeePool.addr.balance, 3_993_980_120_018_203_418);
        assertEq(daoFeePool.balance, 15_975_920_480_072_813_674);
    }
}

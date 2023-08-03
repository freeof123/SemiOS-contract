// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { console2 } from "forge-std/Console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { Denominations } from "@chainlink/contracts/src/v0.8/Denominations.sol";

import { ID4ASettingsReadable, TestERC20, DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { AggregatorV3Mock } from "test/foundry/utils/mocks/AggregatorV3Mock.sol";

import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4ARoyaltySplitter } from "contracts/royalty-splitter/D4ARoyaltySplitter.sol";

contract D4ARoyaltySplitterFactoryTest is DeployHelper {
    uint256 public protocolShare;
    address public daoFeePool1;
    address public daoFeePool2;
    uint96 royaltyFee = 750;
    TestERC20 _testERC20_1 = new TestERC20();
    bytes32 daoId1;
    bytes32 daoId2;
    D4ARoyaltySplitter splitter1;
    D4ARoyaltySplitter splitter2;
    uint256 tokenPrice;
    uint256 tokenPriceDecimal;

    function setUp() public {
        setUpEnv();
        _setUpKeepEnv();
    }

    function test_impl() public {
        assertTrue(address(royaltySplitterFactory.impl()) != address(0));
        assertEq(royaltySplitterFactory.impl().WETH(), address(weth));
    }

    function test_royaltySplitters() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        bytes32 daoId = _createDao(createDaoParam);
        assertEq(address(royaltySplitterFactory.royaltySplitters(2)), address(daoProxy.royaltySplitters(daoId)));
        vm.expectRevert();
        royaltySplitterFactory.royaltySplitters(3);
    }

    function test_createD4ARoyaltySplitter() public {
        D4ARoyaltySplitter splitter = D4ARoyaltySplitter(
            payable(royaltySplitterFactory.createD4ARoyaltySplitter(protocolFeePool.addr, 100, address(this), 200))
        );
        assertEq(splitter.protocolFeePool(), protocolFeePool.addr);
        assertEq(splitter.protocolShare(), 100);
        assertEq(splitter.daoFeePool(), address(this));
        assertEq(splitter.daoShare(), 200);
        assertEq(splitter.threshold(), 5 ether);
        assertEq(address(splitter.router()), address(uniswapV2Router));
        assertEq(splitter.WETH(), address(weth));

        assertEq(splitter.owner(), address(this));
    }

    event NewD4ARoyaltySplitter(address addr);

    function test_createD4ARoyaltySplitter_ExpectEmit() public {
        vm.expectEmit(true, true, true, false);
        emit NewD4ARoyaltySplitter(address(0));
        royaltySplitterFactory.createD4ARoyaltySplitter(protocolFeePool.addr, 100, address(this), 200);
    }

    function _setUpKeepEnv() internal {
        vm.startPrank(protocolOwner.addr);
        feedRegistry.setAggregator(
            address(_testERC20_1), Denominations.ETH, address(new AggregatorV3Mock(1e18 / 2_000, 18))
        );
        vm.stopPrank();
        (, int256 temp,,,) = feedRegistry.latestRoundData(address(_testERC20_1), Denominations.ETH);
        tokenPrice = uint256(temp);
        tokenPriceDecimal = feedRegistry.decimals(address(_testERC20_1), Denominations.ETH);
        protocolShare = ID4ASettingsReadable(address(protocol)).tradeProtocolFeeRatio();

        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.daoUri = "test dao uri 1";
        daoId1 = _createDao(createDaoParam);

        splitter1 = D4ARoyaltySplitter(payable(daoProxy.royaltySplitters(daoId1)));
        daoFeePool1 = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId1);

        createDaoParam.daoUri = "test dao uri 2";
        daoId2 = _createDao(createDaoParam);

        splitter2 = D4ARoyaltySplitter(payable(daoProxy.royaltySplitters(daoId2)));
        daoFeePool2 = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId2);

        deal(address(_testERC20), daoCreator.addr, 1e8 ether * 10 ** tokenPriceDecimal / tokenPrice);
        deal(address(_testERC20_1), daoCreator.addr, 1e8 ether * 10 ** tokenPriceDecimal / tokenPrice);

        startHoax(daoCreator.addr);
        _testERC20.approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{ value: 1e6 ether }(
            address(_testERC20),
            1e6 ether * 10 ** tokenPriceDecimal / tokenPrice,
            0,
            0,
            daoCreator.addr,
            type(uint256).max
        );
        _testERC20_1.approve(address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{ value: 1e6 ether }(
            address(_testERC20_1),
            1e6 ether * 10 ** tokenPriceDecimal / tokenPrice,
            0,
            0,
            daoCreator.addr,
            type(uint256).max
        );
        SafeTransferLib.safeTransferETH(address(weth), 10 ether);
        IERC20(weth).transfer(address(splitter1), 10 ether);
        vm.stopPrank();

        deal(address(_testERC20), address(splitter1), 10 ether * 10 ** tokenPriceDecimal / tokenPrice);
        deal(address(_testERC20_1), address(splitter1), 5 ether * 10 ** tokenPriceDecimal / tokenPrice);
        deal(address(_testERC20), address(splitter2), 5 ether * 10 ** tokenPriceDecimal / tokenPrice);
        deal(address(_testERC20_1), address(splitter2), 10 ether * 10 ** tokenPriceDecimal / tokenPrice);
    }

    function test_checkUpkeep() public returns (bytes memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = address(_testERC20);
        tokens[1] = address(_testERC20_1);
        bytes memory checkData = abi.encode(tokens);
        splitter1.checkUpkeep(checkData);
        (bool upkeepNeeded, bytes memory performData) = royaltySplitterFactory.checkUpkeep(checkData);
        assertTrue(upkeepNeeded);
        address[] memory splitters = new address[](2);
        splitters[0] = address(splitter1);
        splitters[1] = address(splitter2);
        bytes[] memory performDatas = new bytes[](2);
        address[] memory returnTokens = new address[](1);
        returnTokens[0] = address(_testERC20);
        performDatas[0] = abi.encode(IERC20(weth).balanceOf(address(splitter1)), returnTokens);
        returnTokens[0] = address(_testERC20_1);
        performDatas[1] = abi.encode(IERC20(weth).balanceOf(address(splitter2)), returnTokens);
        assertEq(performData, abi.encode(splitters, performDatas));
        return abi.encode(splitters, performDatas);
    }

    function test_performUpkeep() public {
        bytes memory performData = test_checkUpkeep();

        uint256 protocolFeePoolBalanceBefore = protocolFeePool.addr.balance;
        uint256 daoFeePoolBalanceBefore1 = daoFeePool1.balance;
        uint256 daoFeePoolBalanceBefore2 = daoFeePool2.balance;
        uint256 protocolFee;
        uint256 daoFee1;
        uint256 daoFee2;
        {
            address[] memory paths = new address[](2);
            paths[0] = address(_testERC20);
            paths[1] = address(weth);
            uint256 token1ToETHAmount =
                uniswapV2Router.getAmountsOut(10 ether * 10 ** tokenPriceDecimal / tokenPrice, paths)[1];
            paths[0] = address(_testERC20_1);
            uint256 token2ToETHAmount =
                uniswapV2Router.getAmountsOut(10 ether * 10 ** tokenPriceDecimal / tokenPrice, paths)[1];
            uint256 protocolFee1 = (10 ether + token1ToETHAmount) * protocolShare / royaltyFee;
            uint256 protocolFee2 = token2ToETHAmount * protocolShare / royaltyFee;
            protocolFee = protocolFee1 + protocolFee2;
            daoFee1 = (10 ether + token1ToETHAmount) - protocolFee1;
            daoFee2 = token2ToETHAmount - protocolFee2;
        }

        royaltySplitterFactory.performUpkeep(performData);

        assertEq(IERC20(weth).balanceOf(address(splitter1)), 0, "splitter1 weth balance should be 0");
        assertEq(IERC20(weth).balanceOf(address(splitter2)), 0, "splitter2 weth balance should be 0");
        assertEq(_testERC20.balanceOf(address(splitter1)), 0, "splitter1 token balance should be 0");
        assertEq(
            _testERC20_1.balanceOf(address(splitter1)),
            5 ether * 10 ** tokenPriceDecimal / tokenPrice,
            "splitter1 token balance should be 10_000 UDSC"
        );
        assertEq(
            _testERC20.balanceOf(address(splitter2)),
            5 ether * 10 ** tokenPriceDecimal / tokenPrice,
            "splitter2 token balance should be 10_000 ether"
        );
        assertEq(_testERC20_1.balanceOf(address(splitter2)), 0, "splitter2 token balance should be 0");
        assertEq(
            protocolFeePool.addr.balance,
            protocolFeePoolBalanceBefore + protocolFee,
            "protocol fee should be sent to protocol fee pool"
        );
        assertEq(daoFeePool1.balance, daoFeePoolBalanceBefore1 + daoFee1, "dao fee should be sent to dao fee pool");
        assertEq(daoFeePool2.balance, daoFeePoolBalanceBefore2 + daoFee2, "dao fee should be sent to dao fee pool");
    }

    function test_RevertIf_performUpkeep_BeingFrontRunned() public {
        bytes memory performData = test_checkUpkeep();

        // front run to dump test ERC20 1 token price
        startHoax(randomGuy.addr);
        deal(address(_testERC20_1), randomGuy.addr, 1e4 ether * 10 ** tokenPriceDecimal / tokenPrice);
        _testERC20_1.approve(address(uniswapV2Router), _testERC20_1.balanceOf(randomGuy.addr));
        address[] memory paths = new address[](2);
        paths[0] = address(_testERC20_1);
        paths[1] = address(weth);
        uniswapV2Router.swapExactTokensForETH(
            _testERC20_1.balanceOf(randomGuy.addr), 0, paths, randomGuy.addr, block.timestamp + 1
        );

        vm.expectRevert("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        royaltySplitterFactory.performUpkeep(performData);
    }

    function test_performUpkeep_OnlySomeSplittersNeedToPerformUpkeep() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(_testERC20);
        tokens[1] = address(_testERC20_1);
        bytes memory checkData = abi.encode(tokens);
        splitter1.checkUpkeep(checkData);
        (bool upkeepNeeded, bytes memory performData) = royaltySplitterFactory.checkUpkeep(checkData);
        assertTrue(upkeepNeeded);
        address[] memory splitters = new address[](2);
        splitters[0] = address(splitter1);
        splitters[1] = address(splitter2);
        bytes[] memory performDatas = new bytes[](2);
        address[] memory returnTokens = new address[](1);
        returnTokens[0] = address(_testERC20);
        performDatas[0] = abi.encode(IERC20(weth).balanceOf(address(splitter1)), returnTokens);
        returnTokens[0] = address(_testERC20_1);
        performDatas[1] = abi.encode(IERC20(weth).balanceOf(address(splitter2)), returnTokens);
        assertEq(performData, abi.encode(splitters, performDatas));

        uint256 protocolFeePoolBalanceBefore = protocolFeePool.addr.balance;
        uint256 daoFeePoolBalanceBefore1 = daoFeePool1.balance;
        uint256 daoFeePoolBalanceBefore2 = daoFeePool2.balance;
        uint256 protocolFee;
        uint256 daoFee1;
        uint256 daoFee2;
        {
            address[] memory paths = new address[](2);
            paths[0] = address(_testERC20);
            paths[1] = address(weth);
            uint256 token1ToETHAmount =
                uniswapV2Router.getAmountsOut(10 ether * 10 ** tokenPriceDecimal / tokenPrice, paths)[1];
            paths[0] = address(_testERC20_1);
            uint256 token2ToETHAmount =
                uniswapV2Router.getAmountsOut(10 ether * 10 ** tokenPriceDecimal / tokenPrice, paths)[1];
            uint256 protocolFee1 = (10 ether + token1ToETHAmount) * protocolShare / royaltyFee;
            uint256 protocolFee2 = token2ToETHAmount * protocolShare / royaltyFee;
            protocolFee = protocolFee1 + protocolFee2;
            daoFee1 = (10 ether + token1ToETHAmount) - protocolFee1;
            daoFee2 = token2ToETHAmount - protocolFee2;
        }

        royaltySplitterFactory.performUpkeep(performData);

        assertEq(IERC20(weth).balanceOf(address(splitter1)), 0, "splitter1 weth balance should be 0");
        assertEq(IERC20(weth).balanceOf(address(splitter2)), 0, "splitter2 weth balance should be 0");
        assertEq(_testERC20.balanceOf(address(splitter1)), 0, "splitter1 token balance should be 0");
        assertEq(
            _testERC20_1.balanceOf(address(splitter1)),
            5 ether * 10 ** tokenPriceDecimal / tokenPrice,
            "splitter1 token balance should be 10_000 UDSC"
        );
        assertEq(
            _testERC20.balanceOf(address(splitter2)),
            5 ether * 10 ** tokenPriceDecimal / tokenPrice,
            "splitter2 token balance should be 10_000 ether"
        );
        assertEq(_testERC20_1.balanceOf(address(splitter2)), 0, "splitter2 token balance should be 0");
        assertEq(
            protocolFeePool.addr.balance,
            protocolFeePoolBalanceBefore + protocolFee,
            "protocol fee should be sent to protocol fee pool"
        );
        assertEq(daoFeePool1.balance, daoFeePoolBalanceBefore1 + daoFee1, "dao fee should be sent to dao fee pool");
        assertEq(daoFeePool2.balance, daoFeePoolBalanceBefore2 + daoFee2, "dao fee should be sent to dao fee pool");
    }
}

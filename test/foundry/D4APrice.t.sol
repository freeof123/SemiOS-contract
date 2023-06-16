// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ID4ASettingsReadable, DeployHelper} from "./utils/DeployHelper.sol";
import {D4APriceHarness} from "./harness/D4ApriceHarness.sol";
import {D4APrice} from "contracts/impl/D4APrice.sol";

contract D4APriceTest is DeployHelper {
    D4APriceHarness public priceHarness;
    bytes32 public daoId = "daoId";
    bytes32 public canvasId1 = "canvasId1";
    bytes32 public canvasId2 = "canvasId2";
    bytes32 public canvasId3 = "canvasId3";
    uint256[] public priceSlots = [0.1 ether, 0.2 ether, 0.3 ether, 0.4 ether, 0.5 ether];
    uint256 public priceRank = 0;
    uint256 public defaultNftPriceMultiplyFactor;
    uint256 public round0 = 0;
    uint256 public round1 = 1;
    uint256 public x1 = 10_000;
    uint256 public x2 = 20_000;
    uint256 public x1_5 = 15_000;

    function setUp() public {
        setUpEnv();
        priceHarness = new D4APriceHarness();
        defaultNftPriceMultiplyFactor = ID4ASettingsReadable(address(protocol)).defaultNftPriceMultiplyFactor();
    }

    function testFuzz_GetCanvasLastPrice(bytes32 daoId, bytes32 canvasId, uint256 round_, uint256 price_) public {
        priceHarness.exposed_updateCanvasPrice(round_, daoId, canvasId, price_, defaultNftPriceMultiplyFactor);
        (uint256 round, uint256 price) = priceHarness.exposed_getCanvasLastPrice(daoId, canvasId);
        assertEq(round, round_);
        assertEq(price, price);
    }

    // At round 0, will get floor price
    function test_GetCanvasNextPrice_MaxPriceZeroRoundAndStartDrb() public {
        uint256 round = 0;
        uint256 price = priceHarness.exposed_getCanvasNextPrice(
            round, priceSlots, priceRank, round, daoId, canvasId1, defaultNftPriceMultiplyFactor
        );
        assertEq(price, priceSlots[0]);
    }

    function testFuzz_GetCanvasNextPrice_MaxPriceZeroRoundAndStartDrb(uint256 round) public {
        uint256 price = priceHarness.exposed_getCanvasNextPrice(
            round, priceSlots, priceRank, round, daoId, canvasId1, defaultNftPriceMultiplyFactor
        );
        assertEq(price, priceSlots[0]);
    }

    function test_GetCanvasNextPrice_MaxPriceZeroRoundNotStartDrb() public {
        uint256 round = 1;
        uint256 startRound = 0;
        uint256 price = priceHarness.exposed_getCanvasNextPrice(
            round, priceSlots, priceRank, startRound, daoId, canvasId1, defaultNftPriceMultiplyFactor
        );
        assertEq(price, priceSlots[0] * D4APrice._PRICE_CHANGE_BASIS_POINT / defaultNftPriceMultiplyFactor);
    }

    function testFuzz_GetCanvasNextPrice_MaxPriceZeroRoundNotStartDrb(uint256 startRound, uint256 round) public {
        vm.assume(startRound < round);
        uint256 price = priceHarness.exposed_getCanvasNextPrice(
            round, priceSlots, priceRank, startRound, daoId, canvasId1, defaultNftPriceMultiplyFactor
        );
        assertEq(price, priceSlots[0] * D4APrice._PRICE_CHANGE_BASIS_POINT / defaultNftPriceMultiplyFactor);
    }

    // function test_UpdateCanvasPrice() public {
    //     price.updateCanvasPrice()
    // }
    // function test_GetCanvasLastPrice() public {
    //     // canvas 1
    //     (uint256 round, uint256 value) = helper.getCanvasLastPrice(daoId, canvasId1);
    //     assertEq(round, round0);
    //     assertEq(value, 0);

    //     // canvas 2
    //     (round, value) = helper.getCanvasLastPrice(daoId, canvasId2);
    //     assertEq(round, round0);
    //     assertEq(value, 0);

    //     uint256 price1 = 0.1 ether;
    //     // update canvas 1
    //     price1 *= x1 / _PRICE_CHANGE_BASIS_POINT;
    //     helper.updateCanvasPrice(round, daoId, canvasId1, price1, x1);
    //     (round, value) = helper.getCanvasLastPrice(daoId, canvasId1);
    //     assertEq(round, round0);
    //     assertEq(value, price1);

    //     uint256 price2 = 0.2 ether;
    //     // update canvas 2
    //     price2 *= x1 / _PRICE_CHANGE_BASIS_POINT;
    //     helper.updateCanvasPrice(round, daoId, canvasId2, price2, x1);
    //     (round, value) = helper.getCanvasLastPrice(daoId, canvasId2);
    //     assertEq(round, round0);
    //     assertEq(value, price2);

    //     // update canvas 1 with double price
    //     price1 *= x2 / _PRICE_CHANGE_BASIS_POINT;
    //     helper.updateCanvasPrice(round, daoId, canvasId1, price1, x2);
    //     (round, value) = helper.getCanvasLastPrice(daoId, canvasId1);
    //     assertEq(round, round0);
    //     assertEq(value, price1);

    //     // update canvas 2 with double price
    //     price2 *= x2 / _PRICE_CHANGE_BASIS_POINT;
    //     helper.updateCanvasPrice(round, daoId, canvasId2, price2, x2);
    //     (round, value) = helper.getCanvasLastPrice(daoId, canvasId2);
    //     assertEq(round, round0);
    //     assertEq(value, price2);

    //     // update canvas 1 with 1.5x price
    //     price1 *= x1_5 / _PRICE_CHANGE_BASIS_POINT;
    //     helper.updateCanvasPrice(round, daoId, canvasId1, price1, x1_5);
    //     (round, value) = helper.getCanvasLastPrice(daoId, canvasId1);
    //     assertEq(round, round0);
    //     assertEq(value, price1);
    // }

    // function test_getCanvasNextPrice() public {
    //     // get next price with 1x price
    //     uint256 price = helper.getCanvasNextPrice(settings, priceSlots, priceRank, round1, daoId, canvasId1, x1);
    //     assertEq(price, 0.1 ether);

    //     // get next price with 2x price
    //     price = helper.getCanvasNextPrice(settings, priceSlots, priceRank, round1, daoId, canvasId1, x2);
    //     assertEq(price, 0.05 ether);

    //     // update price
    //     helper.updateCanvasPrice(settings, daoId, canvasId1, 0.1 ether, x1);

    //     // get next price with 2x price
    //     price = helper.getCanvasNextPrice(settings, priceSlots, priceRank, round1, daoId, canvasId1, x2);
    //     assertEq(price, 0.05 ether);
    // }

    // function test_updateCanvasPrice() public {
    //     helper.updateCanvasPrice(settings, daoId, canvasId1, 10000, 10000);
    //     (uint256 round, uint256 value) = helper.getCanvasLastPrice(daoId, canvasId1);
    //     assertEq(round, 0);
    //     assertEq(value, 10000);
    // }

    // function test_getPriceInRound() public {
    //     uint256 initPrice = 0.1 ether;
    //     // 1x price
    //     D4APrice.last_price memory lastPrice = D4APrice.last_price(round1, initPrice);
    //     uint256 price = helper.getPriceInRound(lastPrice, round1, x1);
    //     assertEq(price, (initPrice * x1) / _PRICE_CHANGE_BASIS_POINT);

    //     // 2x price
    //     price = helper.getPriceInRound(lastPrice, round1, x2);
    //     assertEq(price, (initPrice * x2) / _PRICE_CHANGE_BASIS_POINT);
    // }
}

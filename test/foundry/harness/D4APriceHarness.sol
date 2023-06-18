// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { D4APrice } from "contracts/impl/D4APrice.sol";

contract D4APriceHarness {
    using D4APrice for D4APrice.project_price_info;

    mapping(bytes32 daoId => D4APrice.project_price_info) public prices;

    function exposed_getCanvasLastPrice(
        bytes32 daoId,
        bytes32 canvasId
    )
        public
        view
        returns (uint256 round, uint256 value)
    {
        (round, value) = prices[daoId].getCanvasLastPrice(canvasId);
    }

    function exposed_getCanvasNextPrice(
        uint256 currentRound,
        uint256[] memory priceSlots,
        uint256 priceRank,
        uint256 startDrb,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 multiplyFactor
    )
        public
        view
        returns (uint256 price)
    {
        price =
            prices[daoId].getCanvasNextPrice(currentRound, priceSlots, priceRank, startDrb, canvasId, multiplyFactor);
    }

    function exposed_updateCanvasPrice(
        uint256 currentRound,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 price,
        uint256 multiplyFactor
    )
        public
    {
        prices[daoId].updateCanvasPrice(currentRound, canvasId, price, multiplyFactor);
    }

    function exposed_getPriceInRound(
        D4APrice.last_price memory lastPrice,
        uint256 currentRound,
        uint256 multiplyFactor
    )
        public
        pure
        returns (uint256 price)
    {
        price = D4APrice._get_price_in_round(lastPrice, currentRound, multiplyFactor);
    }
}

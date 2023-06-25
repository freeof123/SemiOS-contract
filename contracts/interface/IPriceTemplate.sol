// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPriceTemplate {
    function getCanvasNextPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceMultiplierInBps
    )
        external
        view
        returns (uint256);

    function updateCanvasPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 currentRound,
        uint256 price,
        uint256 priceMultiplierInBps
    )
        external;
}

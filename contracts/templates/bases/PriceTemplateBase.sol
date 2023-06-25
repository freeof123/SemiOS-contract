// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IPriceTemplate } from "contracts/interface/IPriceTemplate.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";

abstract contract PriceTemplateBase is IPriceTemplate {
    function getCanvasNextPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceFactor
    )
        public
        view
        returns (uint256)
    {
        uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
        PriceStorage.MintInfo storage maxPrice = PriceStorage.layout().maxPrices[daoId];
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().lastMintInfos[canvasId];

        if (maxPrice.round == 0) {
            if (currentRound == startRound) return daoFloorPrice;
            else return daoFloorPrice >> 1;
        }

        uint256 price = _getPriceInRound(mintInfo, currentRound, priceFactor);
        if (price >= daoFloorPrice) {
            return price;
        }

        price = _getPriceInRound(maxPrice, currentRound, priceFactor);
        if (price >= daoFloorPrice) {
            return daoFloorPrice;
        }
        if (maxPrice.price == daoFloorPrice >> 1 && currentRound <= maxPrice.round + 1) {
            return daoFloorPrice;
        }

        return daoFloorPrice >> 1;
    }

    function updateCanvasPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 currentRound,
        uint256 price,
        uint256 priceFactor
    )
        public
    {
        PriceStorage.MintInfo storage maxPrice = PriceStorage.layout().maxPrices[daoId];
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().lastMintInfos[canvasId];

        uint256 maxPriceToCurrentRound = _getPriceInRound(maxPrice, currentRound, priceFactor);
        if (price >= maxPriceToCurrentRound) {
            maxPrice.round = currentRound;
            maxPrice.price = price;
        }

        mintInfo.round = currentRound;
        mintInfo.price = price;
    }

    function _getPriceInRound(
        PriceStorage.MintInfo memory mintInfo,
        uint256 round,
        uint256 priceFactor
    )
        internal
        pure
        virtual
        returns (uint256);
}

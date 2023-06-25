// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IPriceTemplate } from "../interface/IPriceTemplate.sol";
import { BASIS_POINT } from "../interface/D4AConstants.sol";
import { PriceStorage } from "../storages/PriceStorage.sol";

contract ExponentialPriceTemplate is IPriceTemplate {
    function getCanvasNextPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceMultiplierInBps
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

        uint256 price = _getPriceInRound(mintInfo, currentRound, priceMultiplierInBps);
        if (price >= daoFloorPrice) {
            return price;
        }

        price = _getPriceInRound(maxPrice, currentRound, priceMultiplierInBps);
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
        uint256 priceMultiplierInBps
    )
        public
    {
        PriceStorage.MintInfo storage maxPrice = PriceStorage.layout().maxPrices[daoId];
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().lastMintInfos[canvasId];

        uint256 maxPriceToCurrentRound = _getPriceInRound(maxPrice, currentRound, priceMultiplierInBps);
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
        uint256 priceMultiplierInBps
    )
        internal
        pure
        returns (uint256)
    {
        if (round == mintInfo.round) {
            return mintInfo.price * priceMultiplierInBps / BASIS_POINT;
        }
        uint256 k = round - mintInfo.round - 1;
        uint256 price = mintInfo.price;
        for (uint256 i; i < k;) {
            price = price * BASIS_POINT / priceMultiplierInBps;
            if (price == 0) return 0;
            unchecked {
                ++i;
            }
        }
        return price;
    }
}

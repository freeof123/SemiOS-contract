// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { ExponentialPriceVariation } from "contracts/templates/ExponentialPriceVariation.sol";

contract ExponentialPriceVariationHarness is ExponentialPriceVariation {
    function exposed_getPriceInRound(
        PriceStorage.MintInfo memory mintInfo,
        uint256 round,
        uint256 priceMultiplierInBps
    )
        public
        pure
        returns (uint256)
    {
        return _getPriceInRound(mintInfo, round, priceMultiplierInBps);
    }
}

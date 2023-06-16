// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDrb {
    function currentRound() external view returns (uint256 drbRound);
}

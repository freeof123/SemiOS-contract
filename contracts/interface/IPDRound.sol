// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPDRound {
    error TokenNotAllowed(address token);

    function getDaoCurrentRound(bytes32 daoId) external view returns (uint256 currentRound);
}

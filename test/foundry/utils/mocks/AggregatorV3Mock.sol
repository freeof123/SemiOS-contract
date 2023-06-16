// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract AggregatorV3Mock {
    int256 public answer;
    uint8 public decimals;

    constructor(int256 _answer, uint8 _decimals) {
        answer = _answer;
        decimals = _decimals;
    }

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, answer, 0, 0, 0);
    }
}

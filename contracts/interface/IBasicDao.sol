// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBasicDao {
    function isUnlocked(bytes32 daoId) external view returns (bool);
}

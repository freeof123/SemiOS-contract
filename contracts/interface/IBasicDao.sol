// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBasicDao {
    event BasicDaoUnlocked(bytes32 indexed daoId);

    function unlock(bytes32 daoId) external;

    function ableToUnlock(bytes32 daoId) external view returns (bool);

    function isUnlocked(bytes32 daoId) external view returns (bool);
}

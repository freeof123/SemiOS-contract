// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPDRound {
    function getDaoCurrentRound(bytes32 daoId) external view returns (uint256 currentRound);
    function setDaoDuation(bytes32 daoId, uint256 duration) external;
    function getDaoLastModifyBlock(bytes32 daoId) external view returns (uint256);
    function getDaoLastModifyRound(bytes32 daoId) external view returns (uint256);
}

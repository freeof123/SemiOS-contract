// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library PoolStorage {
    struct PoolInfo {
        mapping(uint256 round => uint256 totalWeight) roundTotalETH;
        uint256 circulateERC20Amount; //????here??
        // mapping(address investor => bytes32[] daoId) investedTopUpDaos;
        // mapping(address investor => uint256 amount) topUpInvestorETHQuota;
        // mapping(address investor => uint256 amount) topUpInvestorERC20Quota;
        mapping(bytes32 nftHash => bytes32[] daoId) nftInvestedTopUpDaos;
        mapping(bytes32 nftHash => uint256 amount) topUpNftETH;
        mapping(bytes32 nftHash => uint256 amount) topUpNftERC20;
    }

    struct Layout {
        mapping(address pool => PoolInfo poolInfo) poolInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.PoolStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

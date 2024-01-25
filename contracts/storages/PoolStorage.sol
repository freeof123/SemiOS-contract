// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library PoolStorage {
    struct LokcedInfo {
        uint256 duration;
        uint256 lockStartBlock;
    }

    struct PoolInfo {
        mapping(uint256 round => uint256 totalWeight) roundTotalETH;
        uint256 circulateERC20Amount; //????here??
        mapping(bytes32 nftHash => bytes32[] daoId) nftInvestedTopUpDaos;
        mapping(bytes32 nftHash => uint256 amount) topUpNftETH;
        uint256 defaultTopUpEthToRedeemPoolRatio;
        mapping(bytes32 nftHash => uint256 amount) topUpNftERC20;
        uint256 defaultTopUpErc20ToTreasuryRatio;
        mapping(bytes32 nftHash => LokcedInfo) lockedInfo;
        address treasury;
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

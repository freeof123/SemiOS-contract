// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { NftIdentifier } from "contracts/interface/D4AStructs.sol";

library PoolStorage {
    struct PoolInfo {
        mapping(uint256 round => uint256 totalWeight) roundTotalEth;
        uint256 circulateERC20Amount; //deprecated
        mapping(bytes32 nftHash => bytes32[] daoId) nftInvestedTopUpDaos;
        mapping(bytes32 nftHash => uint256 amount) topUpNftEth;
        mapping(bytes32 nftHash => uint256 amount) topUpNftErc20;
        //1.6 add-----------------------------------------
        uint256 defaultTopUpEthToRedeemPoolRatio;
        uint256 defaultTopUpErc20ToTreasuryRatio;
        address treasury;
        address grantTreasuryNft;
        //1.8 add-----------------------------------------
        bytes32[] allPlans;
        uint256 totalPlans;
        uint256 totalStakeEth;
        uint256 totalStakeErc20;
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

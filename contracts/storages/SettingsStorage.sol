// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import { ID4ADrb } from "../interface/ID4ADrb.sol";
import { ID4AFeePoolFactory } from "../interface/ID4AFeePoolFactory.sol";
import { ID4AERC20Factory } from "../interface/ID4AERC20Factory.sol";
import { ID4AERC721Factory } from "../interface/ID4AERC721Factory.sol";
import { ID4AOwnerProxy } from "../interface/ID4AOwnerProxy.sol";
import { IPermissionControl } from "../interface/IPermissionControl.sol";
import { ID4ARoyaltySplitterFactory } from "contracts/interface/ID4ARoyaltySplitterFactory.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

library SettingsStorage {
    struct Layout {
        // fee related //deprecated
        uint256 protocolMintFeeRatioInBps;
        uint256 protocolRoyaltyFeeRatioInBps;
        uint256 minRoyaltyFeeRatioInBps;
        uint256 maxRoyaltyFeeRatioInBps;
        uint256 protocolERC20RewardRatio;
        // contract address
        address protocolFeePool;
        ID4ADrb drb;
        ID4AERC20Factory erc20Factory;
        ID4AERC721Factory erc721Factory;
        ID4AFeePoolFactory feePoolFactory;
        ID4AOwnerProxy ownerProxy;
        IPermissionControl permissionControl;
        // params
        uint256 tokenMaxSupply;
        uint256[] nftMaxSupplies;
        address assetOwner;
        bool isProtocolPaused;
        mapping(bytes32 => bool) pauseStatuses;
        uint256 reservedDaoAmount;
        address[256] priceTemplates;
        address[256] rewardTemplates;
        //-------1.3 add
        ID4ARoyaltySplitterFactory royaltySplitterFactory;
        IUniswapV2Factory d4aswapFactory;
        mapping(bytes32 daoId => address royaltySplitter) royaltySplitters;
        address royaltySplitterOwner;
        uint256 protocolETHRewardRatio;
        //-------1.8 add
        address[256] planTemplates;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.Settings");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

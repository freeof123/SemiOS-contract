// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import { ID4ADrb } from "../interface/ID4ADrb.sol";
import { ID4AFeePoolFactory } from "../interface/ID4AFeePoolFactory.sol";
import { ID4AERC20Factory } from "../interface/ID4AERC20Factory.sol";
import { ID4AERC721Factory } from "../interface/ID4AERC721Factory.sol";
import { ID4AOwnerProxy } from "../interface/ID4AOwnerProxy.sol";
import { IPermissionControl } from "../interface/IPermissionControl.sol";

library SettingsStorage {
    struct Layout {
        uint256 create_project_fee;
        address protocolFeePool;
        uint256 create_canvas_fee;
        uint256 mint_d4a_fee_ratio;
        uint256 trade_d4a_fee_ratio;
        uint256 mint_project_fee_ratio;
        uint256 mint_project_fee_ratio_flat_price;
        uint256 erc20_total_supply;
        uint256 project_max_rounds; //366
        uint256 daoCreatorERC20RatioInBps;
        uint256 canvas_erc20_ratio;
        uint256 protocolERC20RatioInBps;
        uint256 rf_lower_bound;
        uint256 rf_upper_bound;
        uint256[] floor_prices;
        uint256[] max_nft_amounts;
        ID4ADrb drb;
        string erc20_name_prefix;
        string erc20_symbol_prefix;
        ID4AERC721Factory erc721_factory;
        ID4AERC20Factory erc20_factory;
        ID4AFeePoolFactory feepool_factory;
        ID4AOwnerProxy owner_proxy;
        IPermissionControl permission_control;
        address asset_pool_owner;
        bool d4a_pause;
        mapping(bytes32 => bool) pause_status;
        address project_proxy;
        uint256 reserved_slots;
        address[256] priceTemplates;
        address[256] rewardTemplates;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.Settings");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

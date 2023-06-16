// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ProtoDAOSettingsBaseStorage.sol";
import "./IProtoDAOSettingsReadable.sol";

import "../D4ASettings/D4ASettingsBaseStorage.sol";

contract ProtoDAOSettingsReadable is IProtoDAOSettingsReadable {
    function getCanvasCreatorERC20Ratio(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (di.canvasCreatorERC20Ratio == 0 && di.nftMinterERC20Ratio == 0) {
            return l.canvas_erc20_ratio;
        }
        return di.canvasCreatorERC20Ratio * (l.ratio_base - l.d4a_erc20_ratio - l.project_erc20_ratio) / l.ratio_base;
    }

    function getNftMinterERC20Ratio(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (di.canvasCreatorERC20Ratio == 0 && di.nftMinterERC20Ratio == 0) {
            return 0;
        }
        return di.nftMinterERC20Ratio * (l.ratio_base - l.d4a_erc20_ratio - l.project_erc20_ratio) / l.ratio_base;
    }

    function getDaoFeePoolETHRatio(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];
        if (di.daoFeePoolETHRatio == 0) {
            return D4ASettingsBaseStorage.layout().mint_project_fee_ratio;
        }
        return di.daoFeePoolETHRatio;
    }

    function getDaoFeePoolETHRatioFlatPrice(bytes32 dao_id) public view returns (uint256) {
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[dao_id];

        if (di.daoFeePoolETHRatioFlatPrice == 0) {
            return D4ASettingsBaseStorage.layout().mint_project_fee_ratio_flat_price;
        }
        return di.daoFeePoolETHRatioFlatPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IProtoDAOSettingsWritable } from "./IProtoDAOSettingsWritable.sol";
import "./ProtoDAOSettingsBaseStorage.sol";
import "./ProtoDAOSettingsReadable.sol";
import "../D4ASettings/D4ASettingsBaseStorage.sol";
import { NotDaoOwner, InvalidERC20Ratio, InvalidETHRatio } from "contracts/interface/D4AErrors.sol";

contract ProtoDAOSettingsWritable is IProtoDAOSettingsWritable {
    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        public
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId) && msg.sender != l.project_proxy) revert NotDaoOwner();
        if (canvasCreatorERC20Ratio + nftMinterERC20Ratio != l.ratio_base) {
            revert InvalidERC20Ratio();
        }
        uint256 ratioBase = l.ratio_base;
        uint256 d4aETHRatio = l.mint_d4a_fee_ratio;
        if (daoFeePoolETHRatioFlatPrice > ratioBase - d4aETHRatio || daoFeePoolETHRatio > daoFeePoolETHRatioFlatPrice) {
            revert InvalidETHRatio();
        }

        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[daoId];
        di.canvasCreatorERC20Ratio = canvasCreatorERC20Ratio;
        di.nftMinterERC20Ratio = nftMinterERC20Ratio;
        di.daoFeePoolETHRatio = daoFeePoolETHRatio;
        di.daoFeePoolETHRatioFlatPrice = daoFeePoolETHRatioFlatPrice;

        emit DaoRatioSet(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { OPERATION_ROLE } from "contracts/interface/D4AConstants.sol";
import { NotDaoOwner } from "contracts/interface/D4AErrors.sol";

import { NotOperationRole } from "contracts/interface/D4AErrors.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";
import { RoundStorage } from "contracts/storages/RoundStorage.sol";
import { SettingsStorage } from "contracts/storages/SettingsStorage.sol";
import { BasicDaoStorage } from "contracts/storages/BasicDaoStorage.sol";
import { InheritTreeStorage } from "contracts/storages/InheritTreeStorage.sol";

contract PDRound is IPDRound {
    function setDaoDuation(bytes32 daoId, uint256 duration) public {
        _checkSetAbility(daoId);
        RoundStorage.RoundInfo storage roundInfo = RoundStorage.layout().roundInfos[daoId];
        uint256 currentRound = getDaoCurrentRound(daoId);
        roundInfo.roundDuration = duration;
        roundInfo.blockInLastModify = block.number;
        roundInfo.roundInLastModify = currentRound;
    }

    function _checkSetAbility(bytes32 daoId) internal view {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        if (msg.sender == address(this)) return;
        bytes32 ancestor = InheritTreeStorage.layout().inheritTreeInfos[daoId].ancestor;
        if (
            msg.sender == settingsStorage.ownerProxy.ownerOf(daoId)
                || msg.sender == settingsStorage.ownerProxy.ownerOf(ancestor)
        ) return;
        revert NotDaoOwner();
    }

    function getDaoCurrentRound(bytes32 daoId) public view returns (uint256) {
        RoundStorage.RoundInfo storage roundInfo = RoundStorage.layout().roundInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        if (roundInfo.roundDuration == 0) return settingsStorage.drb.currentRound();
        if (block.number < roundInfo.blockInLastModify) {
            return 0;
        }
        return (block.number - roundInfo.blockInLastModify) / roundInfo.roundDuration + roundInfo.roundInLastModify;
    }
}

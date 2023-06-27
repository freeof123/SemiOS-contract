// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { DaoMintInfo, UserMintInfo, UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { NotDaoOwner } from "contracts/interface/D4AErrors.sol";

import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { D4ASettingsBaseStorage } from "contracts/D4ASettings/D4ASettingsBaseStorage.sol";

contract D4AProtocolWithPermission is D4AProtocol { }

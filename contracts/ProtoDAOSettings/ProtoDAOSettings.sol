// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IProtoDAOSettings} from "./IProtoDAOSettings.sol";
import {ProtoDAOSettingsReadable} from "./ProtoDAOSettingsReadable.sol";
import {ProtoDAOSettingsWritable} from "./ProtoDAOSettingsWritable.sol";

contract ProtoDAOSettings is IProtoDAOSettings, ProtoDAOSettingsReadable, ProtoDAOSettingsWritable {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IProtoDAOSettingsReadable } from "./IProtoDAOSettingsReadable.sol";
import { IProtoDAOSettingsWritable } from "./IProtoDAOSettingsWritable.sol";

interface IProtoDAOSettings is IProtoDAOSettingsReadable, IProtoDAOSettingsWritable { }

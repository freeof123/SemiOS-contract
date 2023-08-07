// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ID4AProtocol } from "contracts/interface/ID4AProtocol.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4aSettings.sol";
import { ID4AGrant } from "contracts/interface/ID4AGrant.sol";

interface ID4AProtocolAggregate is
    ID4AProtocol,
    ID4AProtocolReadable,
    ID4AProtocolSetter,
    ID4ASettingsReadable,
    ID4ASettings,
    ID4AGrant
{ }

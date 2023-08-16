// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ID4ACreate } from "contracts/interface/ID4ACreate.sol";
import { IPDProtocol } from "contracts/interface/IPDProtocol.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4aSettings.sol";
import { ID4AGrant } from "contracts/interface/ID4AGrant.sol";

interface IPDProtocolAggregate is
    IPDProtocol,
    IPDCreate,
    ID4ACreate,
    IPDProtocolReadable,
    ID4AProtocolSetter,
    ID4ASettingsReadable,
    ID4ASettings,
    ID4AGrant
{ }

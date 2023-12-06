// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ID4ACreate } from "contracts/interface/ID4ACreate.sol";
import { IPDProtocol } from "contracts/interface/IPDProtocol.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolSetter } from "contracts/interface/IPDProtocolSetter.sol";

import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4ASettings } from "contracts/D4ASettings/ID4ASettings.sol";
import { IPDBasicDao } from "contracts/interface/IPDBasicDao.sol";
import { IPDGrant } from "contracts/interface/IPDGrant.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";

interface IPDProtocolAggregate is
    IPDProtocol,
    IPDCreate,
    IPDBasicDao,
    IPDProtocolReadable,
    IPDGrant,
    ID4ACreate,
    ID4AProtocolSetter,
    ID4ASettingsReadable,
    ID4ASettings,
    IPDProtocolSetter
{
    function testBug(bytes32) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/console2.sol";

import { D4AAddress } from "./utils/D4AAddress.sol";
import { FeedRegistryMock } from "test/foundry/utils/mocks/FeedRegistryMock.sol";
import { AggregatorV3Mock } from "test/foundry/utils/mocks/AggregatorV3Mock.sol";

contract FeedRegistryMockScript is Script, D4AAddress {
    using stdJson for string;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        AggregatorV3Mock aggregator = new AggregatorV3Mock(1e18 / 2000, 18);
        FeedRegistryMock(oracleRegistry).setAggregator(
            0x07865c6E87B9F70255377e024ace6630C1Eaa37F, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, address(aggregator)
        );

        vm.stopBroadcast();
    }
}

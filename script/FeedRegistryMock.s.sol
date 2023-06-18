// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/Console2.sol";

import { D4AAddress } from "./utils/D4AAddress.sol";
import { FeedRegistryMock } from "test/foundry/utils/mocks/FeedRegistryMock.sol";

contract FeedRegistryMockScript is Script, D4AAddress {
    using stdJson for string;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        FeedRegistryMock registry =
        new FeedRegistryMock{salt: 0xc769c7d0e1159c53805361a65aed876db7ce897be2b0e14d011237bc07fcab0c}(vm.addr(vm.envUint("PRIVATE_KEY")));
        vm.toString(address(registry)).write(path, ".FeedRegistryMock");

        vm.stopBroadcast();
    }
}

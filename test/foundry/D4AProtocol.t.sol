// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DeployHelper } from "./utils/DeployHelper.sol";
import { MintNftSigUtils } from "./utils/MintNftSigUtils.sol";

contract D4AProtocolTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    function setUp() public {
        setUpEnv();

        sigUtils = new MintNftSigUtils(address(protocol));
    }
}

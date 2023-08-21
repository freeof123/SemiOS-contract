// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";
import { LibBitmap } from "solady/utils/LibBitmap.sol";
import { ProtoDaoProtocolSetter } from "../../../contracts/ProtoDaoProtocolSetter.sol";
import { DeployHelper } from "../../foundry/utils/DeployHelper.sol";
import "contracts/interface/D4AStructs.sol";

import { IProtoDaoProtocol } from "contracts/interface/IProtoDaoProtocol.sol";

contract BasicDaoUnlockerTest is Test, ProtoDaoProtocolSetter, DeployHelper {
    // 初始化Dao
    function setUp() public {
        setUpEnv();

        DeployHelper.CreateDaoParam memory createDaoParam;
        bytes32 daoId = _





    }

    // 验证  流水不足2ETH时无法解锁/流水超过2ETH时可以解锁
    function test_UnlockStatus() public { }

    // 验证  对流水不足的Dao增加到2ETH，后可以解锁
    function test_CanUnlockAfterRaseTo2ETH() public { }

    //
}

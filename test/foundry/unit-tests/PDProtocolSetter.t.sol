// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { PDProtocolReadable } from "contracts/PDProtocolReadable.sol";
import { PDProtocolSetter } from "contracts/PDProtocolSetter.sol";

contract PDProtocolSetterTest is DeployHelper {
    MintNftSigUtils public sigUtils;
    address originalDaoFeePoolAddress;
    address continuousDaoFeePoolAddress;
    address originalTokenAddress;
    address continuousTokenAddress;
    bytes32 cDaoId; // 延续的Dao的Id

    // function setUp() public {
    //     setUpEnv();

    //     DeployHelper.CreateDaoParam memory createDaoParam;
    //     bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     createDaoParam.canvasId = canvasId;
    //     bytes32 daoId = _createBasicDao(createDaoParam);

    //     bytes32 canvasId2 = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
    //     createDaoParam.canvasId = canvasId2;
    //     createDaoParam.daoUri = "continuous dao";
    //     bool needMintableWork = false;

    //     bytes32 continuousDaoId = _createContinuousDao(createDaoParam, daoId, needMintableWork);

    //     originalDaoFeePoolAddress = protocol.getDaoFeePool(daoId);
    //     continuousDaoFeePoolAddress = protocol.getDaoFeePool(continuousDaoId);

    //     originalTokenAddress = protocol.getDaoToken(daoId);
    //     continuousTokenAddress = protocol.getDaoToken(continuousDaoId);
    // }

    // function test_SetDaoMintCapAndPermmision() public {
    //     assertEq(originalTokenAddress, continuousTokenAddress);
    // }
}

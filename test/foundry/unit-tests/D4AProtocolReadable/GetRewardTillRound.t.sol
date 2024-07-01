// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";

contract GetRewardTillRoundTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function _createDaoAndCanvas(
        uint256 mintableRound,
        RewardTemplateType rewardTemplateType,
        uint256 rewardDecayFactor,
        bool isProgressiveJackpot
    )
        internal
    {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.mintableRound = mintableRound;
        param.rewardTemplateType = rewardTemplateType;
        param.rewardDecayFactor = rewardDecayFactor;
        param.isProgressiveJackpot = isProgressiveJackpot;
        param.needMintableWork = true;
        param.noPermission = true;

        daoId = _createDaoForFunding(param, daoCreator.addr);

        vm.roll(2);
        // hoax(canvasCreator.addr);
        // canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);
        canvasId = bytes32(uint256(101));
        super._createCanvasAndMintNft(
            daoId,
            canvasId,
            "create canvas token",
            "origin canvas",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

contract EventMock is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_fundingEvent() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.topUpMode = false;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        super._mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );
        // param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        // param.existDaoId = bytes32(0);
        // param.isBasicDao = true;
        // param.topUpMode = false;
        // param.topUpMode = true;
        // bytes32 daoId2 = _createDaoForFunding(param, daoCreator.addr);
        drb.changeRound(2);
        ClaimMultiRewardParam memory claimParam;
        claimParam.protocol = address(protocol);
        bytes32[] memory cavansIds = new bytes32[](1);
        cavansIds[0] = param.canvasId;

        bytes32[] memory daoIds = new bytes32[](1);
        daoIds[0] = daoId;
        claimParam.canvasIds = cavansIds;
        claimParam.daoIds = daoIds;
        universalClaimer.claimMultiReward(claimParam);
    }
}

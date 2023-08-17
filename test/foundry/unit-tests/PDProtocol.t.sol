// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { PDProtocolHarness } from "test/foundry/harness/PDProtocolHarness.sol";

contract PDProtocolTest is DeployHelper {
    function setUp() public {
        setUpEnv();
        PDProtocolHarness temp = new PDProtocolHarness();
        vm.etch(address(protocolImpl), address(temp).code);
    }

    function testFuzz_exposed_isSpecialTokenUri(uint256 tokenId) public {
        tokenId = bound(tokenId, 0, 999);

        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertTrue(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", vm.toString(tokenId), ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_ExceedDefaultNftNumber() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "1000", ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_NotValidNumber() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "test", ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_WrongPrefix() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        string memory wrongPrefix = tokenUriPrefix;
        bytes(wrongPrefix)[1] = "a";

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(wrongPrefix, vm.toString(daoIndex), "-", "999", ".json")
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

contract PDProtocolSetterTest is DeployHelper {
    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.Settings");
    MintNftSigUtils public sigUtils;
    address originalDaoFeePoolAddress;
    address continuousDaoFeePoolAddress;
    address originalTokenAddress;
    address continuousTokenAddress;
    bytes32 cDaoId; // 延续的Dao的Id

    function setUp() public {
        setUpEnv();
    }

    function test_changeMaxNftAmounts() public {
        uint256[] memory nftMaxAmounts = new uint256[](6);
        nftMaxAmounts[0] = 1000;
        nftMaxAmounts[1] = 5000;
        nftMaxAmounts[2] = 10_000;
        nftMaxAmounts[3] = 50_000;
        nftMaxAmounts[4] = 100_000;
        nftMaxAmounts[5] = 200_000;
        vm.prank(protocolRoleMember.addr);
        protocol.changeMaxNFTAmounts(nftMaxAmounts);
        assertEq(uint256(vm.load(address(protocol), STORAGE_SLOT)), protocol.mintProtocolFeeRatio());
        assertEq(
            uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 1))), protocol.tradeProtocolFeeRatio()
        );
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 2))), 0);
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 3))), 1000);
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 4))), 200);
        assertEq(
            address(uint160(uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 5))))),
            protocolFeePool.addr
        );
        assertEq(
            uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 11))),
            1_000_000_000_000_000_000_000_000_000
        );
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(STORAGE_SLOT) + 12))), 6);
        //--------------------------------------------------------------------------------
        bytes32 amountSlot = keccak256(abi.encode(uint256(STORAGE_SLOT) + 12));
        assertEq(uint256(vm.load(address(protocol), amountSlot)), 1000);
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(amountSlot) + 1))), 5000);
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(amountSlot) + 2))), 10_000);
        assertEq(uint256(vm.load(address(protocol), bytes32(uint256(amountSlot) + 3))), 50_000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { D4ADrb } from "contracts/D4ADrb.sol";

contract D4ADrbTest is Test {
    D4ADrb public drb;

    function setUp() public {
        uint256 blocksPerDrb = 3000 * 1e18;
        drb = new D4ADrb(1, blocksPerDrb);
    }

    // drb grow slower than real time, cut current drb smaller
    // day |________|________|
    //     0        2k  3k   4k
    // drb |____________|____|
    // Actual blocks per day is 2000
    // At the start of day 2, 4000 blocks have passed
    // In drb, it's still drb 1
    // Cut drb 1 at 4000 blocks
    function test_case_1() public {
        assertEq(drb.getStartBlock(0), 1);
        assertEq(drb.getStartBlock(1), 3001);
        assertEq(drb.getStartBlock(2), 6001);
        assertEq(drb.getStartBlock(3), 9001);

        assertEq(drb.getDrb(1), 0);
        assertEq(drb.getDrb(2000), 0);
        assertEq(drb.getDrb(2001), 0);
        assertEq(drb.getDrb(3000), 0);
        assertEq(drb.getDrb(3001), 1);
        assertEq(drb.getDrb(4000), 1);
        assertEq(drb.getDrb(4001), 1);
        assertEq(drb.getDrb(7000), 2);
        assertEq(drb.getDrb(7001), 2);

        vm.roll(1);
        assertEq(drb.currentRound(), 0);
        vm.roll(2000);
        assertEq(drb.currentRound(), 0);
        vm.roll(2001);
        assertEq(drb.currentRound(), 0);
        vm.roll(3000);
        assertEq(drb.currentRound(), 0);
        vm.roll(3001);
        assertEq(drb.currentRound(), 1);
        vm.roll(4000);
        assertEq(drb.currentRound(), 1);
        vm.roll(4001);
        assertEq(drb.currentRound(), 1);
        vm.roll(7000);
        assertEq(drb.currentRound(), 2);
        vm.roll(7001);
        assertEq(drb.currentRound(), 2);

        drb.setNewCheckpoint(2, 4001, 3000 * 1e18);

        assertEq(drb.getStartBlock(0), 1);
        assertEq(drb.getStartBlock(1), 3001);
        assertEq(drb.getStartBlock(2), 4001);
        assertEq(drb.getStartBlock(3), 7001);

        assertEq(drb.getDrb(1), 0);
        assertEq(drb.getDrb(2000), 0);
        assertEq(drb.getDrb(2001), 0);
        assertEq(drb.getDrb(3000), 0);
        assertEq(drb.getDrb(3001), 1);
        assertEq(drb.getDrb(4000), 1);
        assertEq(drb.getDrb(4001), 2);
        assertEq(drb.getDrb(7000), 2);
        assertEq(drb.getDrb(7001), 3);

        vm.roll(1);
        assertEq(drb.currentRound(), 0);
        vm.roll(2000);
        assertEq(drb.currentRound(), 0);
        vm.roll(2001);
        assertEq(drb.currentRound(), 0);
        vm.roll(3000);
        assertEq(drb.currentRound(), 0);
        vm.roll(3001);
        assertEq(drb.currentRound(), 1);
        vm.roll(4000);
        assertEq(drb.currentRound(), 1);
        vm.roll(4001);
        assertEq(drb.currentRound(), 2);
        vm.roll(7000);
        assertEq(drb.currentRound(), 2);
        vm.roll(7001);
        assertEq(drb.currentRound(), 3);
    }

    // drb grow faster than real time, cut current drb bigger
    // day |________________|________________|
    //     0           3k   4k               8k
    // drb |____________|____________________|
    // Actual blocks per day is 4000
    // At the end of day 0, 3999 blocks have passed
    // In drb, it's drb 1 already
    // Cut drb 1 at 8000 blocks
    // Drb 1 has 5000 blocks
    function test_case_2() public {
        assertEq(drb.getStartBlock(0), 1);
        assertEq(drb.getStartBlock(1), 3001);
        assertEq(drb.getStartBlock(2), 6001);
        assertEq(drb.getStartBlock(3), 9001);

        assertEq(drb.getDrb(1), 0);
        assertEq(drb.getDrb(3000), 0);
        assertEq(drb.getDrb(3001), 1);
        assertEq(drb.getDrb(4000), 1);
        assertEq(drb.getDrb(4001), 1);
        assertEq(drb.getDrb(6000), 1);
        assertEq(drb.getDrb(6001), 2);
        assertEq(drb.getDrb(8000), 2);
        assertEq(drb.getDrb(8001), 2);
        assertEq(drb.getDrb(9000), 2);
        assertEq(drb.getDrb(9001), 3);

        vm.roll(1);
        assertEq(drb.currentRound(), 0);
        vm.roll(3000);
        assertEq(drb.currentRound(), 0);
        vm.roll(3001);
        assertEq(drb.currentRound(), 1);
        vm.roll(4000);
        assertEq(drb.currentRound(), 1);
        vm.roll(4001);
        assertEq(drb.currentRound(), 1);
        vm.roll(6000);
        assertEq(drb.currentRound(), 1);
        vm.roll(6001);
        assertEq(drb.currentRound(), 2);
        vm.roll(8000);
        assertEq(drb.currentRound(), 2);
        vm.roll(8001);
        assertEq(drb.currentRound(), 2);
        vm.roll(9000);
        assertEq(drb.currentRound(), 2);
        vm.roll(9001);
        assertEq(drb.currentRound(), 3);

        drb.setNewCheckpoint(2, 8001, 3000 * 1e18);

        assertEq(drb.getStartBlock(0), 1);
        assertEq(drb.getStartBlock(1), 3001);
        assertEq(drb.getStartBlock(2), 8001);
        assertEq(drb.getStartBlock(3), 11_001);

        assertEq(drb.getDrb(1), 0);
        assertEq(drb.getDrb(3000), 0);
        assertEq(drb.getDrb(3001), 1);
        assertEq(drb.getDrb(4000), 1);
        assertEq(drb.getDrb(4001), 1);
        assertEq(drb.getDrb(6000), 1);
        assertEq(drb.getDrb(6001), 1);
        assertEq(drb.getDrb(8000), 1);
        assertEq(drb.getDrb(8001), 2);
        assertEq(drb.getDrb(9000), 2);
        assertEq(drb.getDrb(9001), 2);
        assertEq(drb.getDrb(11_000), 2);
        assertEq(drb.getDrb(11_001), 3);

        vm.roll(1);
        assertEq(drb.currentRound(), 0);
        vm.roll(3000);
        assertEq(drb.currentRound(), 0);
        vm.roll(3001);
        assertEq(drb.currentRound(), 1);
        vm.roll(4000);
        assertEq(drb.currentRound(), 1);
        vm.roll(4001);
        assertEq(drb.currentRound(), 1);
        vm.roll(6000);
        assertEq(drb.currentRound(), 1);
        vm.roll(6001);
        assertEq(drb.currentRound(), 1);
        vm.roll(8000);
        assertEq(drb.currentRound(), 1);
        vm.roll(8001);
        assertEq(drb.currentRound(), 2);
        vm.roll(9000);
        assertEq(drb.currentRound(), 2);
        vm.roll(9001);
        assertEq(drb.currentRound(), 2);
        vm.roll(11_000);
        assertEq(drb.currentRound(), 2);
        vm.roll(11_001);
        assertEq(drb.currentRound(), 3);
    }
}

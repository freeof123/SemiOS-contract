// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DeployHelper} from "./utils/DeployHelper.sol";
import {ProtoDAOSettings} from "contracts/ProtoDAOSettings/ProtoDAOSettings.sol";
import {NotDaoOwner, InvalidERC20Ratio, InvalidETHRatio} from "contracts/interface/D4AErrors.sol";

contract ProtoDAOSettingsTest is DeployHelper {
    function setUp() public {
        setUpEnv();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));
    }

    function test_getCanvasCreatorERC20Ratio() public {
        assertEq(ProtoDAOSettings(address(protocol)).getCanvasCreatorERC20Ratio(bytes32(0)), 9_500);
    }

    function test_getNftMinterERC20Ratio() public {
        assertEq(ProtoDAOSettings(address(protocol)).getNftMinterERC20Ratio(bytes32(0)), 0);
    }

    function test_getDaoFeePoolETHRatio() public {
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatio(bytes32(0)), 3_000);
    }

    function test_getDaoFeePoolETHRatioFlatPrice() public {
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatioFlatPrice(bytes32(0)), 3_500);
    }

    function test_setRatio() public {
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1_000, 9_000, 1_000, 1_100);
        assertEq(ProtoDAOSettings(address(protocol)).getCanvasCreatorERC20Ratio(bytes32(0)), 1_000 * 95 / 100);
        assertEq(ProtoDAOSettings(address(protocol)).getNftMinterERC20Ratio(bytes32(0)), 9_000 * 95 / 100);
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatio(bytes32(0)), 1_000);
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatioFlatPrice(bytes32(0)), 1_100);
    }

    function test_RevertIf_setRatio_NotDaoOwner() public {
        vm.expectRevert(NotDaoOwner.selector);
        vm.prank(randomGuy.addr);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1_000, 8_500, 1_000, 1_100);
    }

    function test_RevertIf_setRatio_InvalidERC20Ratio() public {
        vm.expectRevert(InvalidERC20Ratio.selector);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1_000, 10_000, 1_000, 1_100);
    }

    function test_RevertIf_setRatio_InvalidETHRatio() public {
        vm.expectRevert(InvalidETHRatio.selector);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1_000, 9_000, 9_751, 9_752);
        vm.expectRevert(InvalidETHRatio.selector);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1_000, 9_000, 2_001, 2_000);
    }

    event DaoRatioSet(
        bytes32 daoId,
        uint256 canvasCreatorRatio,
        uint256 nftMinterRatio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    );

    function test_setRatio_ExpectEmit() public {
        vm.expectEmit(address(protocol));
        emit DaoRatioSet(bytes32(0), 1_000, 9_000, 1_000, 1_100);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1_000, 9_000, 1_000, 1_100);
    }
}

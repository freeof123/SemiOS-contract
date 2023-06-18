// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { DeployHelper } from "./utils/DeployHelper.sol";
import { ProtoDAOSettings } from "contracts/ProtoDAOSettings/ProtoDAOSettings.sol";
import { NotDaoOwner, InvalidERC20Ratio, InvalidETHRatio } from "contracts/interface/D4AErrors.sol";

contract ProtoDAOSettingsTest is DeployHelper {
    function setUp() public {
        setUpEnv();

        vm.prank(address(protocol));
        naiveOwner.initOwnerOf(bytes32(0), address(this));
    }

    function test_getCanvasCreatorERC20Ratio() public {
        assertEq(ProtoDAOSettings(address(protocol)).getCanvasCreatorERC20Ratio(bytes32(0)), 9500);
    }

    function test_getNftMinterERC20Ratio() public {
        assertEq(ProtoDAOSettings(address(protocol)).getNftMinterERC20Ratio(bytes32(0)), 0);
    }

    function test_getDaoFeePoolETHRatio() public {
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatio(bytes32(0)), 3000);
    }

    function test_getDaoFeePoolETHRatioFlatPrice() public {
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatioFlatPrice(bytes32(0)), 3500);
    }

    function test_setRatio() public {
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1000, 9000, 1000, 1100);
        assertEq(ProtoDAOSettings(address(protocol)).getCanvasCreatorERC20Ratio(bytes32(0)), 1000 * 95 / 100);
        assertEq(ProtoDAOSettings(address(protocol)).getNftMinterERC20Ratio(bytes32(0)), 9000 * 95 / 100);
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatio(bytes32(0)), 1000);
        assertEq(ProtoDAOSettings(address(protocol)).getDaoFeePoolETHRatioFlatPrice(bytes32(0)), 1100);
    }

    function test_RevertIf_setRatio_NotDaoOwner() public {
        vm.expectRevert(NotDaoOwner.selector);
        vm.prank(randomGuy.addr);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1000, 8500, 1000, 1100);
    }

    function test_RevertIf_setRatio_InvalidERC20Ratio() public {
        vm.expectRevert(InvalidERC20Ratio.selector);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1000, 10_000, 1000, 1100);
    }

    function test_RevertIf_setRatio_InvalidETHRatio() public {
        vm.expectRevert(InvalidETHRatio.selector);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1000, 9000, 9751, 9752);
        vm.expectRevert(InvalidETHRatio.selector);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1000, 9000, 2001, 2000);
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
        emit DaoRatioSet(bytes32(0), 1000, 9000, 1000, 1100);
        ProtoDAOSettings(address(protocol)).setRatio(bytes32(0), 1000, 9000, 1000, 1100);
    }
}

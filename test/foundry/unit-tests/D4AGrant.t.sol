// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";
import { ERC20SigUtils } from "test/foundry/utils/ERC20SigUtils.sol";

import "contracts/interface/D4AErrors.sol";
import { ID4AGrant } from "contracts/interface/ID4AGrant.sol";

contract D4AGrantTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_addAllowedToken() public {
        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        assertTrue(protocol.isTokenAllowed(address(_testERC20)));
    }

    function test_RevertIf_addAllowedToken_NotOperationRole() public {
        vm.expectRevert(NotOperationRole.selector);
        protocol.addAllowedToken(address(_testERC20));
    }

    function test_RevertIf_removeAllowedToken_NotOperationRole() public {
        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        assertTrue(protocol.isTokenAllowed(address(_testERC20)));

        vm.expectRevert(NotOperationRole.selector);
        protocol.removeAllowedToken(address(_testERC20));
    }

    function test_removeAllowedToken() public {
        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        assertTrue(protocol.isTokenAllowed(address(_testERC20)));

        hoax(operationRoleMember.addr);
        protocol.removeAllowedToken(address(_testERC20));

        assertTrue(!protocol.isTokenAllowed(address(_testERC20)));
    }

    function test_removeAllowedToken_MultipleTokens() public {
        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));
        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC721));

        assertTrue(protocol.isTokenAllowed(address(_testERC20)));
        assertTrue(protocol.isTokenAllowed(address(_testERC721)));

        hoax(operationRoleMember.addr);
        protocol.removeAllowedToken(address(_testERC20));

        assertTrue(!protocol.isTokenAllowed(address(_testERC20)));
        assertTrue(protocol.isTokenAllowed(address(_testERC721)));
    }

    function test_grantETH() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        protocol.grantETH{ value: 1 ether }(daoId);
        vm.stopPrank();

        assertEq(protocol.getVestingWallet(daoId).balance, 1 ether);
    }

    function test_grant() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        assertEq(_testERC20.balanceOf(protocol.getVestingWallet(daoId)), 1e6 ether);
    }

    function test_RevertIf_grant_TokenNotAllowed() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        vm.expectRevert(abi.encodeWithSelector(ID4AGrant.TokenNotAllowed.selector, address(_testERC20)));
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
    }

    function test_grantWithPermit() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        ERC20SigUtils sigUtils = new ERC20SigUtils(address(_testERC20));

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        bytes32 digest = sigUtils.getTypedDataHash(randomGuy.addr, address(protocol), 1e6 ether, block.timestamp + 3600);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomGuy.key, digest);
        protocol.grantWithPermit(daoId, address(_testERC20), 1e6 ether, block.timestamp + 3600, v, r, s);
        vm.stopPrank();

        assertEq(_testERC20.balanceOf(protocol.getVestingWallet(daoId)), 1e6 ether);
    }

    function test_RevertIf_grantWithPermit_TokenNotAllowed() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        ERC20SigUtils sigUtils = new ERC20SigUtils(address(_testERC20));

        bytes32 digest = sigUtils.getTypedDataHash(randomGuy.addr, address(protocol), 1e6 ether, block.timestamp + 3600);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomGuy.key, digest);
        vm.expectRevert(abi.encodeWithSelector(ID4AGrant.TokenNotAllowed.selector, address(_testERC20)));
        protocol.grantWithPermit(daoId, address(_testERC20), 1e6 ether, block.timestamp + 3600, v, r, s);
    }

    function test_getVestingWallet() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 daoId = _createDao(param);

        assertEq(protocol.getVestingWallet(daoId), address(0));

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        startHoax(randomGuy.addr);
        deal(address(_testERC20), randomGuy.addr, 1e6 ether);
        _testERC20.approve(address(protocol), 1e6 ether);
        protocol.grant(daoId, address(_testERC20), 1e6 ether);
        vm.stopPrank();

        assertTrue(protocol.getVestingWallet(daoId) != address(0));
    }

    function test_getAllowedTokenList() public {
        assertTrue(protocol.getAllowedTokensList().length == 0);

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        assertTrue(protocol.getAllowedTokensList().length == 1);
        assertTrue(protocol.getAllowedTokensList()[0] == address(_testERC20));

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC721));

        assertTrue(protocol.getAllowedTokensList().length == 2);
        assertTrue(protocol.getAllowedTokensList()[0] == address(_testERC20));
        assertTrue(protocol.getAllowedTokensList()[1] == address(_testERC721));
    }

    function test_isTokenAllowed() public {
        assertTrue(!protocol.isTokenAllowed(address(_testERC20)));

        hoax(operationRoleMember.addr);
        protocol.addAllowedToken(address(_testERC20));

        assertTrue(protocol.isTokenAllowed(address(_testERC20)));
    }
}

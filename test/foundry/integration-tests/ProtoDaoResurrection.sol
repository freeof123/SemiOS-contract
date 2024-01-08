// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

import "forge-std/Test.sol";

contract ProtoDaoResurrectionTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_daoResurrection_basic() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        protocol.setDaoRemainingRound(daoId, 1);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft1", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );

        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0.01 ether * 3500 / 10_000,
            "Distribution about ETH at first amount should be 0.01 * 35%"
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            50_000_000 ether,
            "Distribution about erc20 token at first amount should be 50M"
        );
        //dao become dead
        vm.roll(2);
        vm.expectRevert(ExceedMaxMintableRound.selector);
        hoax(nftMinter.addr);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft2", new bytes32[](0), 0.01 ether, hex"110011", nftMinter.addr
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            0,
            "Distribution about ETH should be 0 before resurrection"
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0 ether,
            "Distribution about erc20 token should be 0 before resurrection"
        );
        //dao had dead and resurrect
        protocol.setDaoRemainingRound(daoId, 20);
        assertEq(protocol.getDaoCurrentRound(daoId), 2);
        assertEq(protocol.getDaoRemainingRound(daoId), 20);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId, address(0), protocol.getDaoCurrentRound(daoId), protocol.getDaoRemainingRound(daoId)
            ),
            protocol.getDaoAssetPool(daoId).balance / 20,
            "Distribution about ETH should be 1/20 of asset pool"
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            2_500_000 ether,
            "Distribution about erc20 token should be 2.5M after resurrection"
        );
    }

    receive() external payable { }
}

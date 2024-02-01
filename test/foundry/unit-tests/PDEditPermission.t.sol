// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import "forge-std/Test.sol";

contract PDEditPermission is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_daoParameterSetControl_noOtherNFT() public {
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.needMintableWork = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        //daoCreator set
        startHoax(daoCreator.addr);
        assertEq(protocol.getDaoRoundMintCap(daoId), 100, "Check A");
        protocol.setRoundMintCap(daoId, 10);
        assertEq(protocol.getDaoRoundMintCap(daoId), 10, "Check B");

        assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000, "Check C");
        protocol.setDaoNftMaxSupply(daoId, 1_000_000);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 1_000_000, "Check D");

        assertEq(protocol.getDaoFloorPrice(daoId), 0.01 ether, "Check E");
        protocol.setDaoFloorPrice(daoId, 1 ether);
        assertEq(protocol.getDaoFloorPrice(daoId), 1 ether, "Check E 2");

        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S");
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 50_000);
        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S1");

        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.01 ether, "Check F");
        protocol.setDaoUnifiedPrice(daoId, 1 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 1 ether, "Check G");

        assertEq(protocol.getDaoRemainingRound(daoId), 60, "Check H");
        protocol.setDaoRemainingRound(daoId, 10);
        assertEq(protocol.getDaoRemainingRound(daoId), 10, "Check I");

        assertEq(protocol.getDaoInfiniteMode(daoId), false, "Check J");
        protocol.changeDaoInfiniteMode(daoId, 1);
        assertEq(protocol.getDaoInfiniteMode(daoId), true, "Check k");

        //transfer nft to randomGuy
        address nft = protocol.getDaoNft(daoId);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        vm.expectRevert(NotNftOwner.selector);
        protocol.setRoundMintCap(daoId, 10);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoNftMaxSupply(daoId, 1_000_000);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoFloorPrice(daoId, 1 ether);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 50_000);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoUnifiedPrice(daoId, 1 ether);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoRemainingRound(daoId, 10);
        vm.expectRevert(NotNftOwner.selector);
        protocol.changeDaoInfiniteMode(daoId, 1);

        startHoax(randomGuy.addr);
        assertEq(protocol.getDaoRoundMintCap(daoId), 10, "Check A 1");
        protocol.setRoundMintCap(daoId, 100);
        assertEq(protocol.getDaoRoundMintCap(daoId), 100, "Check B 1");

        assertEq(protocol.getDaoNftMaxSupply(daoId), 1_000_000, "Check C 1");
        protocol.setDaoNftMaxSupply(daoId, 10);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 10, "Check D 1");

        assertEq(protocol.getDaoFloorPrice(daoId), 1 ether, "Check E 3");
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getDaoFloorPrice(daoId), 0.01 ether, "Check E 2");

        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S 11");
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10);
        assertEq(protocol.getDaoPriceTemplate(daoId), 0x6021944288cC29D790Ad86526107ed5A63150aAa, "Check S 21");

        assertEq(protocol.getDaoUnifiedPrice(daoId), 1 ether, "Check F 1");
        protocol.setDaoUnifiedPrice(daoId, 0.01 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.01 ether, "Check G 1");

        assertEq(protocol.getDaoInfiniteMode(daoId), true, "Check J 1");
        protocol.changeDaoInfiniteMode(daoId, 10);
        assertEq(protocol.getDaoInfiniteMode(daoId), false, "Check k 1");

        assertEq(protocol.getDaoRemainingRound(daoId), 10, "Check H 1");
        protocol.setDaoRemainingRound(daoId, 60);
        assertEq(protocol.getDaoRemainingRound(daoId), 60, "Check I 1");
        // protocol.setDaoEditParamPermission(daoId, 0x123, 1);

        //setDaoParams
        //setChildren
        //setRatio
    }
}

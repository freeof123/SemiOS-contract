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
        assertEq(protocol.getDaoRoundMintCap(daoId), 100, "Check A");
        startHoax(daoCreator.addr);
        protocol.setRoundMintCap(daoId, 10);
        assertEq(protocol.getDaoRoundMintCap(daoId), 10, "Check B");

        console2.log("A", protocol.getDaoNftMaxSupply(daoId));
        protocol.setDaoNftMaxSupply(daoId, 1_000_000);

        console2.log(protocol.getDaoFloorPrice(daoId));
        protocol.setDaoFloorPrice(daoId, 0.1 ether);

        console2.log(protocol.getDaoPriceTemplate(daoId), "C");
        // protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 5);

        console2.log(protocol.getDaoUnifiedPrice(daoId), "D");
        protocol.setDaoUnifiedPrice(daoId, 0.1 ether);

        console2.log(protocol.getDaoRemainingRound(daoId), "E");
        protocol.setDaoRemainingRound(daoId, 10);

        console2.log(protocol.getDaoInfiniteMode(daoId), "F");
        protocol.changeDaoInfiniteMode(daoId, 100);

        //transfer nft to randomGuy
        address nft = protocol.getDaoNft(daoId);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setRoundMintCap(daoId, 10);

        // protocol.setDaoEditParamPermission(daoId, 0x123, 1);

        //setDaoParams
        //setChildren
        //setRatio
    }
}

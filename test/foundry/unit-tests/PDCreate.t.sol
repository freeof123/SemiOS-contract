// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "forge-std/Test.sol";

contract PDCreateTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_createBasicDao() public {
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        assertEq(protocol.getCanvasIdOfSpecialNft(daoId), canvasId, "e1");
        assertEq(naiveOwner.ownerOf(canvasId), daoCreator.addr, "e2");
        assertEq(protocol.getCanvasUri(canvasId), "test dao creator canvas uri", "e3");
        assertEq(IERC20Metadata(protocol.getDaoToken(daoId)).name(), "test dao", "e4");
        assertEq(IERC721Metadata(protocol.getDaoNft(daoId)).name(), "test dao", "e5");
        assertEq(protocol.getDaoTokenMaxSupply(daoId), 5e7 * 1e18, "e6");
        assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000, "e7");
        assertEq(protocol.getDaoNftRoyaltyFeeRatioInBps(daoId), 1250, "e8");
        assertEq(protocol.getDaoMintableRound(daoId), 60, "e9");
        assertEq(protocol.getDaoIsProgressiveJackpot(daoId), true, "e10");

        assertEq(protocol.getDaoCreatorOutputRewardRatio(daoId), 7000);
        assertEq(protocol.getCanvasCreatorOutputRewardRatio(daoId), 2000);
        assertEq(protocol.getMinterOutputRewardRatio(daoId), 800);
        assertEq(protocol.getAssetPoolMintFeeRatio(daoId), 2000);
        assertEq(protocol.getAssetPoolMintFeeRatioFiatPrice(daoId), 3500);
        assertEq(protocol.getDaoNftHolderMintCap(daoId), 0);
        assertEq(protocol.getDaoTag(daoId), "BASIC DAO");
        assertEq(protocol.getDaoIndex(daoId), 110);
    }
}

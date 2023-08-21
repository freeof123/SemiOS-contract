// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

contract PDCreateTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_createBasicDao() public {
        DeployHelper.CreateDaoParam memory param;
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.canvasId = canvasId;
        bytes32 daoId = _createBasicDao(param);

        assertEq(protocol.getCanvasIdOfSpecialNft(daoId), canvasId);
        assertEq(naiveOwner.ownerOf(canvasId), daoCreator.addr);
        assertEq(protocol.getCanvasUri(canvasId), "test dao creator canvas uri");
        assertEq(IERC20Metadata(protocol.getDaoToken(daoId)).name(), "test dao");
        assertEq(IERC721Metadata(protocol.getDaoNft(daoId)).name(), "test dao");
        assertEq(protocol.getDaoTokenMaxSupply(daoId), 5e7 * 1e18);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000);
        assertEq(protocol.getDaoNftRoyaltyFeeRatioInBps(daoId), 1250);
        assertEq(protocol.getDaoMintableRound(daoId), 60);
        assertEq(protocol.getDaoRewardIsProgressiveJackpot(daoId), true);
        assertEq(protocol.getDaoCreatorERC20Ratio(daoId), 4800);
        assertEq(protocol.getCanvasCreatorERC20Ratio(daoId), 2500);
        assertEq(protocol.getNftMinterERC20Ratio(daoId), 2500);
        assertEq(protocol.getDaoFeePoolETHRatio(daoId), 9750);
        assertEq(protocol.getDaoFeePoolETHRatioFlatPrice(daoId), 9750);
        assertEq(protocol.getDaoNftHolderMintCap(daoId), 5);
        assertEq(protocol.getDaoTag(daoId), "BASIC DAO");
    }
}

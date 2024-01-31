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

        assertEq(protocol.getCanvasIdOfSpecialNft(daoId), canvasId);
        assertEq(naiveOwner.ownerOf(canvasId), daoCreator.addr);
        assertEq(protocol.getCanvasUri(canvasId), "test dao creator canvas uri");
        assertEq(IERC20Metadata(protocol.getDaoToken(daoId)).name(), "test dao");
        assertEq(IERC721Metadata(protocol.getDaoNft(daoId)).name(), "test dao");
        assertEq(protocol.getDaoTokenMaxSupply(daoId), 5e7 * 1e18);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000);
        assertEq(protocol.getDaoNftRoyaltyFeeRatioInBps(daoId), 1250);
        assertEq(protocol.getDaoMintableRound(daoId), 60);
        assertEq(protocol.getDaoIsProgressiveJackpot(daoId), true);
        // assertEq(protocol.getDaoCreatorERC20Ratio(daoId), 4800);
        // assertEq(protocol.getCanvasCreatorERC20Ratio(daoId), 2500);
        // assertEq(protocol.getNftMinterERC20Ratio(daoId), 2500);
        // assertEq(protocol.getDaoFeePoolETHRatio(daoId), 9750);
        // assertEq(protocol.getDaoFeePoolETHRatioFlatPrice(daoId), 9750);
        // assertEq(protocol.getDaoNftHolderMintCap(daoId), 5);
        // assertEq(protocol.getDaoTag(daoId), "BASIC DAO");
        // assertEq(protocol.getDaoIndex(daoId), 110);
    }

    function test_createDao_checkExceedTokenMaxTotalSupply_1billoin() public {
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.initTokenSupplyRatio = 10_000;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.initTokenSupplyRatio = 5000;
        param.daoUri = "continuous dao uri";
        vm.expectRevert("setInitialTokenSupplyForSubDao failed");
        _createDaoForFunding(param, daoCreator.addr);
    }

    //     function test_createOwnerBasicDao() public {
    //         DeployHelper.CreateDaoParam memory createDaoParam;
    //         bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //         createDaoParam.canvasId = canvasId;
    //         createDaoParam.projectIndex = 42;
    //         createDaoParam.actionType = 1;
    //         vm.startPrank(operationRoleMember.addr);
    //         DaoMintCapParam memory daoMintCapParam;
    //         {
    //             uint256 length = createDaoParam.minters.length;
    //             daoMintCapParam.userMintCapParams = new UserMintCapParam[](length + 1);
    //             for (uint256 i; i < length;) {
    //                 daoMintCapParam.userMintCapParams[i].minter = createDaoParam.minters[i];
    //                 daoMintCapParam.userMintCapParams[i].mintCap = uint32(createDaoParam.userMintCaps[i]);
    //                 unchecked {
    //                     ++i;
    //                 }
    //             }
    //             daoMintCapParam.userMintCapParams[length].minter = daoCreator.addr;
    //             daoMintCapParam.userMintCapParams[length].mintCap = 5;
    //             daoMintCapParam.daoMintCap = uint32(createDaoParam.mintCap);
    //         }

    //         address[] memory minters = new address[](1);
    //         minters[0] = daoCreator.addr;
    //         createDaoParam.minterMerkleRoot = getMerkleRoot(minters);
    //         bytes32 daoId = daoProxy.createBasicDao(
    //             DaoMetadataParam({
    //                 startDrb: drb.currentRound(),
    //                 mintableRounds: 60,
    //                 floorPriceRank: 0,
    //                 maxNftRank: 2,
    //                 royaltyFee: 1250,
    //                 projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
    //                 projectIndex: createDaoParam.projectIndex
    //             }),
    //             Whitelist({
    //                 minterMerkleRoot: createDaoParam.minterMerkleRoot,
    //                 minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
    //                 canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
    //                 canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses
    //             }),
    //             Blacklist({
    //                 minterAccounts: createDaoParam.minterAccounts,
    //                 canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
    //             }),
    //             daoMintCapParam,
    //             DaoETHAndERC20SplitRatioParam({
    //                 daoCreatorERC20Ratio: 4800,
    //                 canvasCreatorERC20Ratio: 2500,
    //                 nftMinterERC20Ratio: 2500,
    //                 daoFeePoolETHRatio: 9750,
    //                 daoFeePoolETHRatioFlatPrice: 9750
    //             }),
    //             TemplateParam({
    //                 priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
    //                 priceFactor: 20_000,
    //                 rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
    //                 rewardDecayFactor: 0,
    //                 isProgressiveJackpot: true
    //             }),
    //             BasicDaoParam({
    //                 initTokenSupplyRatio: 500,
    //                 canvasId: createDaoParam.canvasId,
    //                 canvasUri: "test dao creator canvas uri",
    //                 daoName: "test dao"
    //             }),
    //             17
    //         );

    //         assertEq(protocol.getCanvasIdOfSpecialNft(daoId), canvasId);
    //         assertEq(naiveOwner.ownerOf(canvasId), operationRoleMember.addr);
    //         assertEq(protocol.getCanvasUri(canvasId), "test dao creator canvas uri");
    //         assertEq(IERC20Metadata(protocol.getDaoToken(daoId)).name(), "test dao");
    //         assertEq(IERC721Metadata(protocol.getDaoNft(daoId)).name(), "test dao");
    //         assertEq(protocol.getDaoTokenMaxSupply(daoId), 5e7 * 1e18);
    //         assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000);
    //         assertEq(protocol.getDaoNftRoyaltyFeeRatioInBps(daoId), 1250);
    //         assertEq(protocol.getDaoMintableRound(daoId), 60);
    //         assertEq(protocol.getDaoRewardIsProgressiveJackpot(daoId), true);
    //         assertEq(protocol.getDaoCreatorERC20Ratio(daoId), 4800);
    //         assertEq(protocol.getCanvasCreatorERC20Ratio(daoId), 2500);
    //         assertEq(protocol.getNftMinterERC20Ratio(daoId), 2500);
    //         assertEq(protocol.getDaoFeePoolETHRatio(daoId), 9750);
    //         assertEq(protocol.getDaoFeePoolETHRatioFlatPrice(daoId), 9750);
    //         assertEq(protocol.getDaoNftHolderMintCap(daoId), 5);
    //         assertEq(protocol.getDaoTag(daoId), "BASIC DAO");
    //         assertEq(protocol.getDaoIndex(daoId), 42);
    //     }

    //     function test_createContinuousDao() public {
    //         address originalDaoFeePoolAddress;
    //         address continuousDaoFeePoolAddress;
    //         address originalTokenAddress;
    //         address continuousTokenAddress;

    //         DeployHelper.CreateDaoParam memory createDaoParam;
    //         bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //         createDaoParam.canvasId = canvasId;
    //         bytes32 daoId = _createBasicDao(createDaoParam);

    //         bytes32 canvasId2 = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
    //         createDaoParam.canvasId = canvasId2;
    //         createDaoParam.daoUri = "continuous dao";
    //         bool needMintableWork = false;
    //         // CreateContinuousDaoParam.initTokenSupplyRatio = 1000;

    //         bytes32 continuousDaoId = _createContinuousDao(createDaoParam, daoId, needMintableWork, true, 1000);

    //         originalDaoFeePoolAddress = protocol.getDaoFeePool(daoId);
    //         continuousDaoFeePoolAddress = protocol.getDaoFeePool(continuousDaoId);
    //         assertEq(originalDaoFeePoolAddress, continuousDaoFeePoolAddress);

    //         originalTokenAddress = protocol.getDaoToken(daoId);
    //         continuousTokenAddress = protocol.getDaoToken(continuousDaoId);
    //         assertEq(originalTokenAddress, continuousTokenAddress);

    //         // 默认basicDao是有1000个预留的，所以这里测试的是没有预留的情况
    //     }
}

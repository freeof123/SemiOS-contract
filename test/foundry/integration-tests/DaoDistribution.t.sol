// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import { PDProtocolSetter } from "contracts/PDProtocolSetter.sol";
import "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { console2 } from "forge-std/Test.sol";

contract DaoDistribution is DeployHelper {
    DeployHelper.CreateDaoParam param;
    bytes32 daoId;
    bytes32 daoId2;
    bytes32 daoId3;
    bytes32 canvasId1;
    bytes32 canvasId_nonFix;
    bytes32 canvasId3;
    address token;
    address token2;

    function setUp() public {
        super.setUpEnv();

        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        canvasId1 = param.canvasId;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardRatioERC20 = 7000;
        param.selfRewardRatioETH = 7000;

        daoId = super._createDaoForFunding(param, daoCreator.addr);
        token = protocol.getDaoToken(daoId);

        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        param.daoUri = "dao uri2";
        param.uniPriceModeOff = true;

        daoId2 = super._createDaoForFunding(param, daoCreator.addr);
        token2 = protocol.getDaoToken(daoId2);
        canvasId_nonFix = param.canvasId;

        //daoCreator2 create a subdao
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp + 2));
        param.daoUri = "dao uri3";
        param.existDaoId = daoId;
        // param.selfRewardRatioERC20 = 10_000;
        // param.selfRewardRatioETH = 10_000;

        daoId3 = super._createDaoForFunding(param, daoCreator2.addr);
        canvasId3 = param.canvasId;
    }

    // 1.3-93
    function test_DistributParamEffectiveTime() public {
        param.daoUri = "continuous dao uri";
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.isBasicDao = false;
        param.existDaoId = daoId;
        bytes32 canvasId2 = param.canvasId;

        bytes32 subDaoId = super._createDaoForFunding(param, daoCreator.addr);

        bytes32[] memory childrenDaoId = new bytes32[](1);
        uint256[] memory erc20Ratios = new uint256[](1);
        uint256[] memory ethRatios = new uint256[](1);
        childrenDaoId[0] = subDaoId;
        erc20Ratios[0] = 5000;
        ethRatios[0] = 5000;
        SetChildrenParam memory setChildrenParam =
            SetChildrenParam(childrenDaoId, erc20Ratios, ethRatios, 2500, 5000, 2500);

        hoax(daoCreator.addr);
        protocol.setChildren(daoId, setChildrenParam);

        deal(daoCreator.addr, 0.01 ether);

        super._mintNftChangeBal(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr
        );

        // children DAO assetPool
        // console2.log("Redeem pool balance:", protocol.getDaoFeePool(subDaoId).balance);
        // console2.log("Children DAO assetPool balance:", protocol.getDaoAssetPool(subDaoId).balance);

        vm.roll(2);

        // // 验证每个角色的分得资产数量
        ClaimMultiRewardParam memory claimParam;
        claimParam.protocol = address(protocol);
        bytes32[] memory cavansIds = new bytes32[](2);
        cavansIds[0] = canvasId1;
        cavansIds[1] = canvasId2;

        bytes32[] memory daoIds = new bytes32[](2);
        daoIds[0] = daoId;
        daoIds[1] = subDaoId;
        claimParam.canvasIds = cavansIds;
        claimParam.daoIds = daoIds;
        // console2.log(protocol.getRoundERC20Reward(daoId, 1));
        vm.prank(daoCreator.addr);
        universalClaimer.claimMultiReward(claimParam);
        //assert
        assertEq(IERC20(token).balanceOf(daoCreator.addr), 50_000_000 / 10 / 2 * 0.98 ether);

        //0.01 * 0.025 ether
        assertEq(daoCreator.addr.balance, 0.01 * 0.025 ether);
    }

    // 1.3-92：修改下面6个
    function test_setAllocationAndMint92() public {
        // deal(daoCreator.addr, 1 ether);
        deal(nftMinter.addr, 0.01 ether);
        // 铸造一个NFT
        super._mintNftChangeBal(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        // 原参数：allRatioForFundingParam: (750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000)
        // 修改ERC20分配比例（Minter: 50%, Builder: 20%, Starter: 28%, PDAO: 2%）
        AllRatioParam memory vars = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 5000, 2000, 2800, 5000, 2000, 2800);
        hoax(daoCreator.addr);
        protocol.setRatio(daoId, vars);

        // 等待Drb结束 奖励分配
        vm.roll(2);
        ClaimMultiRewardParam memory claimParam;
        claimParam.protocol = address(protocol);
        bytes32[] memory cavansIds = new bytes32[](1);
        cavansIds[0] = canvasId1;

        bytes32[] memory daoIds = new bytes32[](1);
        daoIds[0] = daoId;
        claimParam.canvasIds = cavansIds;
        claimParam.daoIds = daoIds;
        vm.prank(daoCreator.addr);
        universalClaimer.claimMultiReward(claimParam);
        vm.prank(nftMinter.addr);
        universalClaimer.claimMultiReward(claimParam);

        // 查看资产分配数量 分配比例应该是修改后的比例
        assertEq(IERC20(token).balanceOf(daoCreator.addr), 3_150_000 ether);
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 280_000 ether);
    }

    // 1.3-91 修改上面6个
    function test_DistributParamInsideDaoEffective() public {
        AllRatioParam memory vars = AllRatioParam(5750, 1000, 3000, 7000, 500, 2250, 800, 2000, 7000, 800, 2000, 7000);
        hoax(daoCreator.addr);

        protocol.setRatio(daoId2, vars);

        deal(daoCreator.addr, 0 ether);
        deal(nftMinter.addr, 0.02 ether);
        // 铸造一个非一口价作品
        super._mintNftChangeBal(
            daoId2, canvasId_nonFix, string.concat("test mint nft"), 0, daoCreator.key, nftMinter.addr
        );

        // 查看非一口价ETH分配比例
        assertEq(daoCreator.addr.balance, 5_750_000_000_000_000);

        // 铸造一个一口价作品
        super._mintNftChangeBal(
            daoId2,
            canvasId_nonFix,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        // 查看一口价ETH分配比例
        assertEq(daoCreator.addr.balance, 12_750_000_000_000_000);
    }

    // 1.3-84
    function test_progressiveJackpotAddToken84() public {
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 84));
        param.daoUri = "lottery mode dao";
        param.uniPriceModeOff = false;
        param.isProgressiveJackpot = true;

        bytes32 jackpotDaoId = super._createDaoForFunding(param, daoCreator.addr);
        bytes32 jackpotCanvasId = param.canvasId;
        uint256 mintableRound;
        address jackpotToken = protocol.getDaoToken(jackpotDaoId);

        // 累计2个Drb
        vm.roll(3);

        // 在铸造前追加1000万Token,
        assertEq(protocol.getDaoTokenMaxSupply(jackpotDaoId), 50_000_000 ether, "e1"); // 追加前总量5000万
        uint256 initialTokenSupply = 10_000_000 ether;
        hoax(daoCreator.addr);
        protocol.grantDaoAssetPool(jackpotDaoId, initialTokenSupply, true, "test");
        assertEq(protocol.getDaoTokenMaxSupply(jackpotDaoId), 60_000_000 ether, "e2"); // 追加后总量6000万

        // 修改MintWindow和之前不一致
        //(, mintableRound,,,,,,) = protocol.getProjectInfo(jackpotDaoId);
        mintableRound = protocol.getDaoMintableRound(jackpotDaoId);
        assertEq(mintableRound, 10);
        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(jackpotDaoId, 18);
        // (, mintableRound,,,,,,) = protocol.getProjectInfo(jackpotDaoId);
        mintableRound = protocol.getDaoMintableRound(jackpotDaoId);
        assertEq(mintableRound, 20);

        // // 铸造一个Nft
        deal(nftMinter.addr, 0.01 ether);
        deal(daoCreator.addr, 0 ether);
        super._mintNftChangeBal(
            jackpotDaoId,
            jackpotCanvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        // 结束Drb验证资产发放    ERC20/ETH
        vm.roll(4);
        ClaimMultiRewardParam memory claimParam;

        claimParam.protocol = address(protocol);
        bytes32[] memory cavansIds = new bytes32[](1);
        cavansIds[0] = jackpotCanvasId;
        bytes32[] memory daoIds = new bytes32[](1);
        daoIds[0] = jackpotDaoId;
        claimParam.canvasIds = cavansIds;
        claimParam.daoIds = daoIds;

        vm.prank(daoCreator.addr);
        universalClaimer.claimMultiReward(claimParam);
        vm.prank(nftMinter.addr);
        universalClaimer.claimMultiReward(claimParam);
        // // 验证DaoCreator 和 NftMinter的奖励分配
        // 60000000/20 *3 *0.7 * (0.2 + 0.7) = 5.670000
        assertEq(IERC20(jackpotToken).balanceOf(daoCreator.addr) / 1 ether, 5_670_000);
        // 60000000/20 *3 *0.7 * (0.08) = 504000
        assertEq(IERC20(jackpotToken).balanceOf(nftMinter.addr) / 1 ether, 504_000);

        // // 再换一个Drb
        vm.roll(5);

        // 先铸造Nft
        deal(nftMinter2.addr, 0.01 ether);
        //erc20 balance: 60000000 - 60000000/20 * 3 * 0.7 = 53700000
        super._mintNftChangeBal(
            jackpotDaoId,
            jackpotCanvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter2.addr
        );

        // 修改Mint window 追加100万Token
        hoax(daoCreator.addr);
        //before: setDaoMintableRound
        protocol.setDaoRemainingRound(jackpotDaoId, 996);
        (, mintableRound,,,,,,) = protocol.getProjectInfo(jackpotDaoId);
        assertEq(mintableRound, 1000);

        initialTokenSupply = 1_000_000 ether;
        //console2.log("asset pool bal:", IERC20(jackpotToken).balanceOf(jackpotPool));
        hoax(daoCreator.addr);
        protocol.grantDaoAssetPool(jackpotDaoId, initialTokenSupply, true, "test");
        //console2.log("asset pool bal:", IERC20(jackpotToken).balanceOf(jackpotPool));

        assertEq(protocol.getDaoTokenMaxSupply(jackpotDaoId), 61_000_000 ether); // 追加后总量6100万

        // DaoCreator 以及 NftMinter2的奖励分配
        vm.roll(6);
        vm.prank(daoCreator.addr);
        universalClaimer.claimMultiReward(claimParam);
        vm.prank(nftMinter2.addr);
        universalClaimer.claimMultiReward(claimParam);
        // 53700000 / 17 * 2 * 0.7 * (0.2 + 0.7) + 5_670_000 = 9_650_117
        assertEq(IERC20(jackpotToken).balanceOf(daoCreator.addr) / 1 ether, 9_650_117);
        assertEq(IERC20(jackpotToken).balanceOf(nftMinter2.addr) / 1 ether, 353_788);
    }

    // test daoCreate2 act as subdao could claim the daoCreator reward
    function test_daoCreator2_asSubDaoCreator_couldClaimReward() public {
        deal(nftMinter.addr, 0.01 ether);
        // 铸造一个NFT
        super._mintNftChangeBal(
            daoId3,
            canvasId3,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );

        vm.roll(3);
        (uint256 ercAmount, uint256 ethAmount) = protocol.claimDaoNftOwnerReward(daoId3);
        assertEq(ercAmount, 50_000_000 ether * 0.7 * 0.7 / 10, "Check A");
        assertEq(ethAmount, 0, "Check B");

        deal(nftMinter.addr, 0.01 ether);
        // 铸造一个NFT
        super._mintNftChangeBal(
            daoId3,
            canvasId3,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );

        vm.roll(5);
        (ercAmount, ethAmount) = protocol.claimDaoNftOwnerReward(daoId3);
        assertApproxEqAbs(ethAmount, 0.01 ether * 0.35 * 0.7 * 0.7 / uint256(9), 10, "Check D");
        //question, daoId3 is not subdao?
        // console2.log(protocol.getDaoToken(daoId3), protocol.getDaoToken(daoId), "A");
    }

    //start add test case for 1.6
    //--------------------------------------------------
    function test_claimReward_daoNftOwner_test() public {
        deal(nftMinter.addr, 0.01 ether);
        // 铸造一个NFT
        super._mintNftChangeBal(
            daoId3,
            canvasId3,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );

        vm.roll(3);
        uint256 balance_before = IERC20(protocol.getDaoToken(daoId3)).balanceOf(daoCreator2.addr);
        (uint256 ercAmount, uint256 ethAmount) = protocol.claimDaoNftOwnerReward(daoId3);
        uint256 balance_after = IERC20(protocol.getDaoToken(daoId3)).balanceOf(daoCreator2.addr);
        assertEq(ercAmount, balance_after - balance_before, "Check A D");

        vm.roll(5);
        address nft = protocol.getDaoNft(daoId3);
        hoax(daoCreator2.addr);
        IERC721(nft).safeTransferFrom(daoCreator2.addr, randomGuy.addr, 0);

        deal(nftMinter.addr, 0.01 ether);
        // 铸造一个NFT
        super._mintNftChangeBal(
            daoId3,
            canvasId3,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );
        vm.roll(7);
        balance_before = IERC20(protocol.getDaoToken(daoId3)).balanceOf(randomGuy.addr);
        (ercAmount,) = protocol.claimDaoNftOwnerReward(daoId3);
        balance_after = IERC20(protocol.getDaoToken(daoId3)).balanceOf(randomGuy.addr);
        assertEq(ercAmount, balance_after - balance_before, "Check A D C");
    }

    //--------------------------------------------------
    //end add test case for 1.6
}

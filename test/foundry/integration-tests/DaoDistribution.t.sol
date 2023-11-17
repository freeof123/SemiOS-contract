// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    bytes32 canvasId1;
    bytes32 canvasId_nonFix;
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
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.uniPriceModeOff = true;

        daoId2 = super._createDaoForFunding(param, daoCreator.addr);
        token2 = protocol.getDaoToken(daoId2);
        canvasId_nonFix = param.canvasId;
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

        drb.changeRound(2);

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
        universalClaimer.claimMultiRewardFunding(claimParam);
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
        AllRatioForFundingParam memory vars =
            AllRatioForFundingParam(750, 2000, 7000, 250, 3500, 6000, 5000, 2000, 2800, 5000, 2000, 2800);
        hoax(daoCreator.addr);
        protocol.setRatioForFunding(daoId, vars);

        // 等待Drb结束 奖励分配
        drb.changeRound(2);
        ClaimMultiRewardParam memory claimParam;
        claimParam.protocol = address(protocol);
        bytes32[] memory cavansIds = new bytes32[](1);
        cavansIds[0] = canvasId1;

        bytes32[] memory daoIds = new bytes32[](1);
        daoIds[0] = daoId;
        claimParam.canvasIds = cavansIds;
        claimParam.daoIds = daoIds;
        vm.prank(daoCreator.addr);
        universalClaimer.claimMultiRewardFunding(claimParam);
        vm.prank(nftMinter.addr);
        universalClaimer.claimMultiRewardFunding(claimParam);

        // 查看资产分配数量 分配比例应该是修改后的比例
        assertEq(IERC20(token).balanceOf(daoCreator.addr), 3_150_000 ether);
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 280_000 ether);
    }

    // 1.3-91 修改上面6个
    function test_DistributParamInsideDaoEffective() public {
        AllRatioForFundingParam memory vars =
            AllRatioForFundingParam(5750, 1000, 3000, 7000, 500, 2250, 800, 2000, 7000, 800, 2000, 7000);
        hoax(daoCreator.addr);

        protocol.setRatioForFunding(daoId2, vars);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { UserMintCapParam, NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoTopUpTest is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    function test_twoDifferentTopUpDaos_accountSholdRemainSame() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.duration = 2 ether;
        param.noPermission = true;
        param.topUpMode = true;
        param.startBlock = 1;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.duration = 2 ether;
        param.noPermission = true;
        param.topUpMode = true;
        param.startBlock = 2;
        param.daoUri = "TEST DAO 2";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator.addr);
        vm.roll(2);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;

        // super._mintNft(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );
        super._mintNftWithParam(nftParam, nftMinter.addr);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        (uint256 topUpERC20_2, uint256 topUpETH_2) = protocol.updateTopUpAccount(daoId2, nft1);

        assertEq(topUpERC20_2, topUpERC20);
        assertEq(topUpETH_2, topUpETH);

        vm.roll(3);

        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        // super._mintNft(
        //     daoId,
        //     canvasId1,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     nftMinter.addr
        // );
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        // super._mintNft(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(1)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        (topUpERC20_2, topUpETH_2) = protocol.updateTopUpAccount(daoId2, nft1);

        assertEq(topUpERC20_2, topUpERC20);
        assertEq(topUpETH_2, topUpETH);

        vm.roll(4);

        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        // super._mintNft(
        //     daoId,
        //     canvasId1,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     nftMinter.addr
        // );
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(2)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        // super._mintNft(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(2)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        (topUpERC20_2, topUpETH_2) = protocol.updateTopUpAccount(daoId2, nft1);

        assertEq(topUpERC20_2, topUpERC20);
        assertEq(topUpETH_2, topUpETH);

        vm.roll(5);

        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        // super._mintNft(
        //     daoId,
        //     canvasId1,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     nftMinter.addr
        // );
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(3)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        // super._mintNft(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(3)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        (topUpERC20_2, topUpETH_2) = protocol.updateTopUpAccount(daoId2, nft1);

        assertEq(topUpERC20_2, topUpERC20);
        assertEq(topUpETH_2, topUpETH);
    }

    // testcase 1.3-15
    function test_PDCreateFunding_1_3_55() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 8000;
        param.selfRewardRatioERC20 = 8000;
        param.noPermission = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.uniPriceModeOff = true;
        param.daoUri = "continuous dao uri";

        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        //step 2
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 0);
        assertEq(topUpETH, 0);

        vm.roll(2);
        //step 4
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParam(nftParam, nftMinter.addr);
        // super._mintNft(
        //     daoId,
        //     canvasId1,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     nftMinter.addr
        // );
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60), "s1: top up erc20");
        assertEq(topUpETH, 0.01 ether, "s1: top up eth");

        deal(nftMinter.addr, 1 ether);
        uint256 balBefore = nftMinter.addr.balance;
        //step 6
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.005 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
        // super._mintNftChangeBal(
        //     daoId2,
        //     canvasId2,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        //     ),
        //     0.005 ether,
        //     daoCreator2.key,
        //     nftMinter.addr
        // );
        assertEq(nftMinter.addr.balance, balBefore);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60) - 50_000_000 ether / uint256(60) / 2);
        assertEq(topUpETH, 0.005 ether);

        //step 11
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = nft1;

        super._mintNftWithParam(nftParam, nftMinter.addr);
        // super._mintNft(
        //     daoId,
        //     canvasId1,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     nftMinter.addr
        // );
        //step 12
        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter2.addr
        );
        NftIdentifier memory nft2 = NftIdentifier(protocol.getDaoNft(daoId), 4);

        vm.roll(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        uint256 a = (50_000_000 ether - 50_000_000 ether / uint256(60)) / 59;
        assertEq(topUpERC20, 50_000_000 ether / uint256(60) - 50_000_000 ether / uint256(60) / 2 + a * 2 / 3);
        assertEq(topUpETH, 0.005 ether + 0.02 ether);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft2);
        assertEq(topUpERC20, a / 3);
        assertEq(topUpETH, 0.01 ether);
    }

    function test_PDCreateFunding_1_3_62() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.topUpMode = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 0;
        param.selfRewardRatioERC20 = 0;
        param.noPermission = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.uniPriceModeOff = true;
        param.daoUri = "continuous dao uri";

        param.childrenDaoId = new bytes32[](1);
        param.childrenDaoId[0] = daoId;
        // erc20 ratio
        param.childrenDaoRatiosERC20 = new uint256[](1);
        param.childrenDaoRatiosERC20[0] = 7000;
        // eth ratio
        param.childrenDaoRatiosETH = new uint256[](1);
        param.childrenDaoRatiosETH[0] = 7000;

        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        vm.prank(daoCreator.addr);
        protocol.grantDaoAssetPool(daoId2, 10_000_000 ether, true, "uri");
        vm.prank(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 0.1 ether);

        address token = protocol.getDaoToken(daoId);
        address pool1 = protocol.getDaoAssetPool(daoId);
        //step 2
        super._mintNft(
            daoId2,
            canvasId2,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator2.key,
            nftMinter.addr
        );
        assertEq(IERC20(token).balanceOf(pool1), 50_000_000 ether + 700_000 ether);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.1 ether,
            daoCreator.key,
            nftMinter.addr
        );
        NftIdentifier memory nft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.1 ether,
            daoCreator.key,
            nftMinter2.addr
        );

        NftIdentifier memory nft2 = NftIdentifier(protocol.getDaoNft(daoId), 2);

        vm.roll(2);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, nft1);
        assertEq(topUpERC20, (50_000_000 ether + 700_000 ether) / 10 / 2);
        assertEq(topUpETH, 0.1 ether);

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, nft2);
        assertEq(topUpERC20, (50_000_000 ether + 700_000 ether) / 10 / 2);
        assertEq(topUpETH, 0.1 ether);
    }

    function test_PDCreate_MainDaoTouUpNotProgressive_SubDaoProgresive() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 8000;
        param.selfRewardRatioERC20 = 8000;
        param.noPermission = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.uniPriceModeOff = true;
        param.daoUri = "continuous dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        NftIdentifier memory mainNft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 0);
        assertEq(topUpETH, 0);

        vm.roll(2);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60));
        assertEq(topUpETH, 0.01 ether);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        vm.roll(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(60), "Topup C");
        assertEq(topUpETH, 0.01 ether, "Topup D");

        NftIdentifier memory mainNft2 = NftIdentifier(protocol.getDaoNft(daoId), 2);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft2);
        assertEq(topUpERC20, (50_000_000 ether - 50_000_000 ether / uint256(60)) / uint256(59), "TopUP A");
        assertEq(topUpETH, 0.01 ether, "Topup B");

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;

        assertEq(IERC20(token).balanceOf(nftMinter.addr), 0, "ERC20 NFTMinter Should Be 0");

        super._mintNftWithParam(nftParam, nftMinter.addr);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId2, mainNft1);
        assertEq(topUpERC20, 0, "mainNFT1 TopUp Balance Should be cost");
        assertEq(topUpETH, 0, "Topup E");
        assertEq(
            IERC20(token).balanceOf(nftMinter.addr), 50_000_000 ether / uint256(60), "ERC20 TopUp  Should not be  0"
        );

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft2);
        assertEq(
            topUpERC20,
            (50_000_000 ether - 50_000_000 ether / uint256(60)) / uint256(59),
            "mainNFT Topup account not change"
        );
        assertEq(topUpETH, 0.01 ether, "Topup B");
    }

    function test_PDCreate_MainDaoTouUpEnd_SubDaoNotEnd() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        param.mintableRound = 3;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 8000;
        param.selfRewardRatioERC20 = 8000;
        param.noPermission = true;
        param.topUpMode = false;
        param.daoUri = "continuous dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        NftIdentifier memory mainNft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 0);
        assertEq(topUpETH, 0);

        vm.roll(2);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(3), "CHECK EE");
        assertEq(topUpETH, 0.01 ether);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        vm.roll(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(3), "Topup C");
        assertEq(topUpETH, 0.01 ether, "Topup D");

        NftIdentifier memory mainNft2 = NftIdentifier(protocol.getDaoNft(daoId), 2);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft2);
        assertEq(topUpERC20, (50_000_000 ether - 50_000_000 ether / uint256(3)) / uint256(2), "TopUP A");
        assertEq(topUpETH, 0.01 ether, "Topup B");

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;

        assertEq(IERC20(token).balanceOf(nftMinter.addr), 0, "ERC20 NFTMinter Should Be 0");

        super._mintNftWithParam(nftParam, nftMinter.addr);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId2, mainNft1);
        assertEq(topUpERC20, 0, "mainNFT1 TopUp Balance Should be cost");
        assertEq(topUpETH, 0, "Topup E");
        assertEq(
            IERC20(token).balanceOf(nftMinter.addr), 50_000_000 ether / uint256(3), "ERC20 TopUp  Should not be  0"
        );

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft2);
        assertEq(
            topUpERC20,
            (50_000_000 ether - 50_000_000 ether / uint256(3)) / uint256(2),
            "mainNFT Topup account not change"
        );
        assertEq(topUpETH, 0.01 ether, "Topup B");

        vm.roll(4);
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = mainNft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        vm.roll(5);
        uint256 daoRemaingRound = protocol.getDaoRemainingRound(daoId);
        assertEq(daoRemaingRound, 0, "main dao remaining round should be 0");
        daoRemaingRound = protocol.getDaoRemainingRound(daoId2);
        assertEq(daoRemaingRound, 2, "sub dao remaining round should be 2");

        //maindao has dead, check whether subdao can mint
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;
        super._mintNftWithParam(nftParam, nftMinter.addr);

        vm.roll(7);
        daoRemaingRound = protocol.getDaoRemainingRound(daoId2);
        assertEq(daoRemaingRound, 1, "sub dao remaining round should be 2");
    }

    function test_topUpNFT_transferToAlice_aliceUsedNFT() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        param.mintableRound = 3;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.selfRewardRatioETH = 8000;
        param.selfRewardRatioERC20 = 8000;
        param.noPermission = true;
        param.topUpMode = false;
        param.daoUri = "continuous dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        NftIdentifier memory mainNft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 0);
        assertEq(topUpETH, 0);

        vm.roll(2);
        address nftAddress = protocol.getDaoNft(daoId);
        vm.prank(nftMinter.addr);
        D4AERC721(nftAddress).safeTransferFrom(nftMinter.addr, randomGuy.addr, 1);

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(3), "CHECK EE");
        assertEq(topUpETH, 0.01 ether);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        vm.roll(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(3), "Topup C");
        assertEq(topUpETH, 0.01 ether, "Topup D");

        NftIdentifier memory mainNft2 = NftIdentifier(protocol.getDaoNft(daoId), 2);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft2);
        assertEq(topUpERC20, (50_000_000 ether - 50_000_000 ether / uint256(3)) / uint256(2), "TopUP A");
        assertEq(topUpETH, 0.01 ether, "Topup B");

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;

        assertEq(IERC20(token).balanceOf(nftMinter.addr), 0, "ERC20 NFTMinter Should Be 0");

        super._mintNftWithParam(nftParam, randomGuy.addr);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId2, mainNft1);
        assertEq(topUpERC20, 0, "mainNFT1 TopUp Balance Should be cost");
        assertEq(topUpETH, 0, "Topup E");
        assertEq(
            IERC20(token).balanceOf(randomGuy.addr), 50_000_000 ether / uint256(3), "ERC20 TopUp  Should not be  0"
        );
    }
}

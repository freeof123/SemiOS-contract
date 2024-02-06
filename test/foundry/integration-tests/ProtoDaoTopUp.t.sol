// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { UserMintCapParam, NftIdentifier } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao, NotNftOwner } from "contracts/interface/D4AErrors.sol";
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

    // add test case for 1.6
    //-------------------------------------------------------------
    function test_topUpDefaultTopUpErc20ToTreasuryRatio_setByTreasuryNFTOwner() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        param.topUpMode = true;
        param.mintableRound = 3;
        param.defaultTopUpErc20ToTreasuryRatio = 5000;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        // first step. deposit money to TopUp NFT by topup daoId
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
        vm.roll(2);
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.noPermission = true;
        param.topUpMode = false;
        param.daoUri = "continuous dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        NftIdentifier memory mainNft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(3), "CHECK 1.6 t1 EE");
        assertEq(topUpETH, 0.01 ether);

        // second step. spent money with TopUp NFT by non-topup daoId2 as default ratia
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
        address treasury = protocol.getDaoTreasury(daoId);
        {
            // address redeemPool = protocol.redeemPool();

            uint256 erc20_before_treasury = IERC20(token).balanceOf(treasury);
            assertEq(nftMinter.addr.balance, 0, "nftMinter.addr.balance should be 0, cost topup account");
            super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
            uint256 erc20_after_treasury = IERC20(token).balanceOf(treasury);
            assertEq(erc20_after_treasury - erc20_before_treasury, topUpERC20 / 2, "ERC20 TopUp  Should not be  0");
            assertEq(IERC20(token).balanceOf(nftMinter.addr), topUpERC20 / 2, "ERC20 TopUp  Should not be  0");

            (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId2, mainNft1);
            assertEq(topUpERC20, 0, "mainNFT1 TopUp Balance Should be cost");
            assertEq(topUpETH, 0, "Topup E");
        }

        //1.6 set default ratio test
        //---------------------------------------------------------------------
        //third step. set default ratio and single ratio permission by treasury NFT owner
        {
            address nftAddress = protocol.getDaoNft(daoId);
            vm.prank(daoCreator.addr);
            D4AERC721(nftAddress).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);
        }
        vm.expectRevert(NotNftOwner.selector);
        vm.prank(daoCreator.addr);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);
        vm.expectRevert(NotNftOwner.selector);
        vm.prank(daoCreator.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        vm.prank(randomGuy.addr);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);
        vm.prank(randomGuy.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        //add external nft set to treasury
        vm.prank(randomGuy.addr);
        protocol.setTreasurySetTopUpRatioPermission(daoId, address(_testERC721), 5);

        _testERC721.mint(daoCreator3.addr, 5);
        vm.expectRevert(NotNftOwner.selector);
        vm.prank(randomGuy.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);
        vm.prank(daoCreator3.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        vm.prank(randomGuy.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);
        vm.prank(daoCreator3.addr);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);

        //1.6 check new create dao as new default ratio
        //forth step. deposit money to TopUp NFT by topup daoId
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = mainNft1;
        deal(nftMinter.addr, 0.01 ether);
        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        );
        deal(nftMinter.addr, 0.01 ether);
        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);

        vm.roll(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertApproxEqAbs(topUpERC20, 50_000_000 ether / uint256(3), 10, "CHECK 1.6 t1 EE t2");
        assertEq(topUpETH, 0.01 ether * 2, "Top Up balance double 2");

        //fifth step. create new dao as new default ratio
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 canvasId3 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.noPermission = true;
        param.topUpMode = false;
        param.daoUri = "continuous dao 3 uri";
        bytes32 daoId3 = super._createDaoForFunding(param, daoCreator2.addr);

        nftParam.daoId = daoId3;
        nftParam.canvasId = canvasId3;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;
        //sixth step. spent money with TopUp NFT by non-topup daoId3 as new default ratia daoId3
        {
            uint256 erc20_before_treasury = IERC20(token).balanceOf(treasury);
            uint256 erc20_before_account = IERC20(token).balanceOf(nftMinter.addr);
            assertEq(nftMinter.addr.balance, 0, "nftMinter.addr.balance should be 0, cost topup account");
            super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
            uint256 erc20_after_treasury = IERC20(token).balanceOf(treasury);
            uint256 erc20_after_account = IERC20(token).balanceOf(nftMinter.addr);
            assertApproxEqAbs(
                erc20_after_account - erc20_before_account,
                topUpERC20 / 2 * 8 / 10,
                10,
                "ERC20 TopUp  Should not be  0 ERC20 For Account A"
            );

            assertEq(
                erc20_after_treasury - erc20_before_treasury,
                topUpERC20 / 2 * 2 / 10,
                "ERC20 TopUp  Should not be  0 ERC20 for treasury A"
            );
        }
        //seven step. spent money with TopUp NFT by non-topup daoId2 as new  ratia daoId2
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;
        {
            uint256 erc20_before_treasury = IERC20(token).balanceOf(treasury);
            uint256 erc20_before_account = IERC20(token).balanceOf(nftMinter.addr);
            assertEq(nftMinter.addr.balance, 0, "nftMinter.addr.balance should be 0, cost topup account");
            super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
            uint256 erc20_after_treasury = IERC20(token).balanceOf(treasury);
            uint256 erc20_after_account = IERC20(token).balanceOf(nftMinter.addr);
            assertApproxEqAbs(
                erc20_after_account - erc20_before_account,
                topUpERC20 / 2 * 2 / 10,
                10,
                "ERC20 TopUp  Should not be  0 ERC20 For Account B"
            );

            assertApproxEqAbs(
                erc20_after_treasury - erc20_before_treasury,
                topUpERC20 / 2 * 8 / 10,
                10,
                "ERC20 TopUp  Should not be  0 ERC20 for treasury B"
            );
        }

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId3, mainNft1);
        assertEq(topUpERC20, 0, "mainNFT1 TopUp Balance Should be cost Check A");
        assertEq(topUpETH, 0, "Topup E Check A");
    }

    function test_topUpDefaultTopUpEthToRedeemPoolRatio_setByTreasuryNFTOwner() public {
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
        param.defaultTopUpEthToRedeemPoolRatio = 5000;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address token = protocol.getDaoToken(daoId);
        // first step. deposit money to TopUp NFT by topup daoId
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

        vm.roll(2);
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 canvasId2 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.noPermission = true;
        param.topUpMode = false;
        param.erc20PaymentMode = true;
        param.unifiedPrice = 100 ether;
        param.daoUri = "continuous dao uri";
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);

        NftIdentifier memory mainNft1 = NftIdentifier(protocol.getDaoNft(daoId), 1);
        (uint256 topUpERC20, uint256 topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);

        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertEq(topUpERC20, 50_000_000 ether / uint256(3), "CHECK 1.6 t1 EE");
        assertEq(topUpETH, 0.01 ether);

        // second step. spent money with TopUp NFT by non-topup daoId2 as default ratia
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 100 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;
        assertEq(IERC20(token).balanceOf(nftMinter.addr), 0, "ERC20 NFTMinter Should Be 0");
        address redeemPool = protocol.getDaoFeePool(daoId);
        {
            // address redeemPool = protocol.redeemPool();
            uint256 eth_before_account = nftMinter.addr.balance;
            uint256 eth_before_redeemPool = redeemPool.balance;
            assertEq(
                IERC20(token).balanceOf(nftMinter.addr), 0, "nftMinter.addr.balance should be 0, cost topup account"
            );
            super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
            uint256 eth_after_redeemPool = redeemPool.balance;
            uint256 eth_after_account = nftMinter.addr.balance;
            assertEq(
                eth_after_redeemPool - eth_before_redeemPool,
                nftParam.flatPrice * 0.01 ether / (50_000_000 ether / uint256(3)) / 2,
                "ETH TopUp  Should not be  0 redeemPool"
            );
            assertEq(
                eth_after_account - eth_before_account,
                nftParam.flatPrice * 0.01 ether / (50_000_000 ether / uint256(3)) / 2,
                "ERC20 TopUp  Should not be  0 Account"
            );

            (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId2, mainNft1);
            assertEq(topUpERC20, 50_000_000 ether / uint256(3) - 100 ether, "mainNFT1 TopUp Balance Should be cost");
            assertEq(
                topUpETH, 0.01 ether - nftParam.flatPrice * 0.01 ether / (50_000_000 ether / uint256(3)), "Topup E"
            );
        }

        //1.6 set default ratio test
        //---------------------------------------------------------------------
        //third step. set default ratio and single ratio permission by treasury NFT owner
        {
            address nftAddress = protocol.getDaoNft(daoId);
            vm.prank(daoCreator.addr);
            D4AERC721(nftAddress).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);
        }
        vm.expectRevert(NotNftOwner.selector);
        vm.prank(daoCreator.addr);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);
        vm.expectRevert(NotNftOwner.selector);
        vm.prank(daoCreator.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        vm.prank(randomGuy.addr);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);
        vm.prank(randomGuy.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        //add external nft set to treasury
        vm.prank(randomGuy.addr);
        protocol.setTreasurySetTopUpRatioPermission(daoId, address(_testERC721), 5);

        _testERC721.mint(daoCreator3.addr, 5);
        vm.expectRevert(NotNftOwner.selector);
        vm.prank(randomGuy.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        vm.prank(daoCreator3.addr);
        protocol.setTopUpBalanceSplitRatio(daoId2, 8000, 8000);

        vm.prank(randomGuy.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);
        vm.prank(daoCreator3.addr);
        protocol.setDefaultTopUpBalanceSplitRatio(daoId, 1000, 2000);

        //1.6 check new create dao as new default ratio
        //forth step. deposit money to TopUp NFT by topup daoId
        nftParam.daoId = daoId;
        nftParam.canvasId = canvasId1;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 0.01 ether;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = mainNft1;
        deal(nftMinter.addr, 0.01 ether);
        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        );
        deal(nftMinter.addr, 0.01 ether);
        super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);

        vm.roll(3);
        (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId, mainNft1);
        assertApproxEqAbs(
            topUpERC20,
            50_000_000 ether / uint256(3) + 50_000_000 ether / uint256(3) - 100 ether,
            10,
            "CHECK 1.6 t1 EE t2"
        );
        assertEq(
            topUpETH,
            0.01 ether * 2 + 0.01 ether - 100 ether * 0.01 ether / (50_000_000 ether / uint256(3)),
            "Top Up balance double 2"
        );

        //fifth step. create new dao as new default ratio
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 canvasId3 = param.canvasId;
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.noPermission = true;
        param.topUpMode = false;
        param.unifiedPrice = 200 ether;
        param.erc20PaymentMode = true;
        param.daoUri = "continuous dao 3 uri";
        bytes32 daoId3 = super._createDaoForFunding(param, daoCreator2.addr);

        nftParam.daoId = daoId3;
        nftParam.canvasId = canvasId3;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId3)), "-", vm.toString(uint256(0)), ".json"
        );
        nftParam.flatPrice = 200 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;
        //sixth step. spent money with TopUp NFT by non-topup daoId3 as new default ratia daoId3
        {
            uint256 eth_before_redeemPool = redeemPool.balance;
            uint256 eth_before_account = nftMinter.addr.balance;
            super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
            uint256 eth_after_redeemPool = redeemPool.balance;
            uint256 eth_after_account = nftMinter.addr.balance;
            assertApproxEqAbs(
                eth_after_redeemPool - eth_before_redeemPool,
                200 ether * topUpETH / topUpERC20 / 10,
                10,
                "ERC20 TopUp  Should not be  0 ERC20 For redeemPool A"
            );

            assertEq(
                eth_after_account - eth_before_account,
                200 ether * topUpETH / topUpERC20 * 9 / 10,
                "ERC20 TopUp  Should not be  0 ERC20 for Account A"
            );
        }
        //seven step. spent money with TopUp NFT by non-topup daoId3 as new  ratia daoId2
        nftParam.daoId = daoId2;
        nftParam.canvasId = canvasId2;
        nftParam.tokenUri = string.concat(
            tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId2)), "-", vm.toString(uint256(1)), ".json"
        );
        nftParam.flatPrice = 100 ether;
        nftParam.canvasCreatorKey = daoCreator2.key;
        nftParam.nftIdentifier = mainNft1;
        {
            uint256 eth_before_redeemPool = redeemPool.balance;
            uint256 eth_before_account = nftMinter.addr.balance;
            super._mintNftWithParamChangeBal(nftParam, nftMinter.addr);
            uint256 eth_after_redeemPool = redeemPool.balance;
            uint256 eth_after_account = nftMinter.addr.balance;
            assertApproxEqAbs(
                eth_after_redeemPool - eth_before_redeemPool,
                100 ether * topUpETH / topUpERC20 * 8 / 10,
                10,
                "ERC20 TopUp  Should not be  0 ERC20 For redeemPool A B"
            );

            assertEq(
                eth_after_account - eth_before_account,
                100 ether * topUpETH / topUpERC20 * 2 / 10,
                "ERC20 TopUp  Should not be  0 ERC20 for Account A B"
            );
        }
        {
            uint256 topUpERC20Before = topUpERC20;
            uint256 topUpETHBefore = topUpETH;
            (topUpERC20, topUpETH) = protocol.updateTopUpAccount(daoId3, mainNft1);
            assertEq(
                topUpERC20, topUpERC20Before - 100 ether - 200 ether, "mainNFT1 TopUp Balance Should be cost Check A"
            );
            assertEq(
                topUpETH,
                topUpETHBefore - (100 ether + 200 ether) * topUpETHBefore / topUpERC20Before,
                "Topup E Check A"
            );
        }
    }
    //-------------------------------------------------------------
    // end test cast for 1.6
}

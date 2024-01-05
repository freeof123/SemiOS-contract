// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

import "forge-std/Test.sol";

contract PDRoundTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_daoDuration() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.duration = 2e18;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        vm.roll(2);
        assertEq(protocol.getDaoCurrentRound(daoId), 1);
        vm.roll(3);
        assertEq(protocol.getDaoCurrentRound(daoId), 2);
        vm.roll(4);
        assertEq(protocol.getDaoCurrentRound(daoId), 2);
        vm.roll(5);
        assertEq(protocol.getDaoCurrentRound(daoId), 3);
        protocol.setDaoDuation(daoId, 2.5e18);
        assertEq(protocol.getDaoCurrentRound(daoId), 3);
        vm.roll(7);
        assertEq(protocol.getDaoCurrentRound(daoId), 3);
        vm.roll(8);
        assertEq(protocol.getDaoCurrentRound(daoId), 4);
        vm.roll(9);
        assertEq(protocol.getDaoCurrentRound(daoId), 4);
        vm.roll(10);
        assertEq(protocol.getDaoCurrentRound(daoId), 5);
        vm.roll(11);
        assertEq(protocol.getDaoCurrentRound(daoId), 5);
        protocol.setDaoDuation(daoId, 3e18);
        vm.roll(12);
        assertEq(protocol.getDaoCurrentRound(daoId), 5);
        vm.roll(13);
        assertEq(protocol.getDaoCurrentRound(daoId), 5);
        vm.roll(14);
        assertEq(protocol.getDaoCurrentRound(daoId), 6);
    }

    function test_setRemainingRound_addRoundAndNoMint() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        vm.roll(5);
        protocol.setDaoRemainingRound(daoId, 10);
        assertEq(protocol.getDaoRemainingRound(daoId), 10);
        vm.roll(13);
        assertEq(protocol.getDaoRemainingRound(daoId), 10);
    }

    function test_setRemainingRoundAndMint() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        super._mintNft(daoId, param.canvasId, "nft1", 0.01 ether, daoCreator.key, nftMinter.addr);
        vm.roll(2);
        super._mintNft(daoId, param.canvasId, "nft2", 0.01 ether, daoCreator.key, nftMinter.addr);
        assertEq(protocol.getDaoRemainingRound(daoId), 9);
        vm.roll(3);
        assertEq(protocol.getDaoRemainingRound(daoId), 8);
        vm.roll(5);
        super._mintNft(daoId, param.canvasId, "nft3", 0.01 ether, daoCreator.key, nftMinter.addr);
        assertEq(protocol.getDaoRemainingRound(daoId), 8);
        protocol.setDaoRemainingRound(daoId, 10);
        assertEq(protocol.getDaoRemainingRound(daoId), 10);
        vm.roll(6);
        assertEq(protocol.getDaoRemainingRound(daoId), 9);
        super._mintNft(daoId, param.canvasId, "nft4", 0.01 ether, daoCreator.key, nftMinter.addr);
        vm.roll(13);
        assertEq(protocol.getDaoRemainingRound(daoId), 8);
        protocol.setDaoRemainingRound(daoId, 3);
        assertEq(protocol.getDaoRemainingRound(daoId), 3);
        super._mintNft(daoId, param.canvasId, "nft5", 0.01 ether, daoCreator.key, nftMinter.addr);
        vm.roll(14);
        assertEq(protocol.getDaoRemainingRound(daoId), 2);
    }

    function test_setRemainingRoundJackpot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        param.isProgressiveJackpot = true;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        vm.roll(2);
        assertEq(protocol.getDaoRemainingRound(daoId), 9);
        vm.roll(3);
        assertEq(protocol.getDaoRemainingRound(daoId), 8);
        vm.roll(5);
        assertEq(protocol.getDaoRemainingRound(daoId), 6);
        protocol.setDaoRemainingRound(daoId, 10);
        assertEq(protocol.getDaoRemainingRound(daoId), 10);
        vm.roll(6);
        assertEq(protocol.getDaoRemainingRound(daoId), 9);
        vm.roll(13);
        assertEq(protocol.getDaoRemainingRound(daoId), 2);
        protocol.setDaoRemainingRound(daoId, 10);
        assertEq(protocol.getDaoRemainingRound(daoId), 10);
        protocol.setDaoRemainingRound(daoId, 3);
        assertEq(protocol.getDaoRemainingRound(daoId), 3);
        vm.roll(14);
        assertEq(protocol.getDaoRemainingRound(daoId), 2);
    }

    function test_rewardChangeWhenSetRemainingRoundJackpot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        param.isProgressiveJackpot = true;
        param.initTokenSupplyRatio = 600;
        param.selfRewardRatioERC20 = 10_000;

        bytes32 daoId = _createDaoForFunding(param, address(this));
        vm.roll(2);
        assertEq(protocol.getDaoRemainingRound(daoId), 9);
        vm.roll(3);
        assertEq(protocol.getDaoRemainingRound(daoId), 8);
        vm.roll(5);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            30_000_000 ether
        );
        assertEq(protocol.getDaoRemainingRound(daoId), 6);
        protocol.setDaoRemainingRound(daoId, 11);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            20_000_000 ether
        );
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft1", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        assertEq(protocol.getDaoRemainingRound(daoId), 11);
        //total: 40000000, mint: block 5,
        vm.roll(15);
        assertEq(protocol.getDaoRemainingRound(daoId), 1);
        //jackpot: 6-15: 10 block
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            40_000_000 ether
        );
        //more 10 block in future
        protocol.setDaoRemainingRound(daoId, 11);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            20_000_000 ether
        );
    }

    function test_daoRestart_basic() public {
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
        vm.roll(2);
        vm.expectRevert(ExceedMaxMintableRound.selector);
        hoax(nftMinter.addr);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft2", new bytes32[](0), 0.01 ether, hex"110011", nftMinter.addr
        );
        protocol.setDaoRemainingRound(daoId, 20);
        assertEq(protocol.getDaoCurrentRound(daoId), 2);
        assertEq(protocol.getDaoRemainingRound(daoId), 20);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            2_500_000 ether,
            "distribution amount should be 2.5M"
        );
    }

    function test_daoRestartAndMintInfoShouldClear() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        param.selfRewardRatioERC20 = 10_000;
        bytes32 daoId = _createDaoForFunding(param, address(this));
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft1", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        vm.roll(2);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft2", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        vm.roll(3);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft3", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        vm.roll(10);
        protocol.setDaoRemainingRound(daoId, 1);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            35_000_000 ether
        );
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft4", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0
        );
        vm.roll(11);
        assertEq(protocol.getDaoRemainingRound(daoId), 0);
        protocol.setDaoRemainingRound(daoId, 20);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0
        );
        assertEq(protocol.getDaoRemainingRound(daoId), 20);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft5", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        vm.roll(12);
        assertEq(protocol.getDaoRemainingRound(daoId), 19);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft6", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        vm.roll(13);
        assertEq(protocol.getDaoRemainingRound(daoId), 18);
    }

    function test_daoRestartAndMintInfoShouldClearJackpot() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 10;
        param.noPermission = true;
        param.isProgressiveJackpot = true;

        bytes32 daoId = _createDaoForFunding(param, address(this));
        vm.roll(10);
        assertEq(protocol.getDaoRemainingRound(daoId), 1);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            50_000_000 ether
        );
        vm.roll(11);
        //dao dead
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0 ether
        );
        protocol.setDaoRemainingRound(daoId, 20);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            2_500_000 ether
        );
        vm.roll(21);
        protocol.mintNFTAndTransfer{ value: 0.01 ether }(
            daoId, param.canvasId, "nft1", new bytes32[](0), 0.01 ether, hex"11", nftMinter.addr
        );
        vm.roll(31);
        //dead
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            0
        );
        //restart
        protocol.setDaoRemainingRound(daoId, 5);
        assertEq(
            protocol.getDaoRoundDistributeAmount(
                daoId,
                protocol.getDaoToken(daoId),
                protocol.getDaoCurrentRound(daoId),
                protocol.getDaoRemainingRound(daoId)
            ),
            10_000_000 ether
        );
    }

    function test_daoRestartAndPriceInfoShouldClear() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.mintableRound = 1;
        param.noPermission = true;
        param.isProgressiveJackpot = true;
        param.uniPriceModeOff = true;
        bytes32 canvasId1 = bytes32(uint256(1));
        bytes32 canvasId2 = bytes32(uint256(2));
        bytes32 canvasId3 = bytes32(uint256(3));

        bytes32 daoId = super._createDaoForFunding(param, address(this));
        super._createCanvasAndMintNft(
            daoId, canvasId1, "nft1", "canvas1", 0, canvasCreator.key, canvasCreator.addr, nftMinter.addr
        );
        super._mintNft(daoId, canvasId1, "nft2", 0, canvasCreator.key, nftMinter.addr);
        super._mintNft(daoId, canvasId1, "nft3", 0, canvasCreator.key, nftMinter.addr);
        super._createCanvasAndMintNft(
            daoId, canvasId2, "nft4", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        );

        super._mintNft(daoId, canvasId2, "nft5", 0, canvasCreator2.key, nftMinter.addr);

        super._createCanvasAndMintNft(
            daoId, canvasId3, "nft6", "canvas3", 0, canvasCreator3.key, canvasCreator3.addr, nftMinter.addr
        );
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.08 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.04 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId3), 0.02 ether);
        vm.roll(2);
        //dead
        protocol.setDaoRemainingRound(daoId, 100);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.01 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId3), 0.01 ether);
        vm.roll(3);
        assertEq(protocol.getCanvasNextPrice(canvasId1), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId2), 0.005 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId3), 0.005 ether);
    }

    receive() external payable { }
}

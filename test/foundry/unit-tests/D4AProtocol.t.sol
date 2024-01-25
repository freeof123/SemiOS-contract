// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import { NotDaoOwner, ExceedMaxMintableRound, NotNftOwner } from "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";

import "contracts/interface/D4AStructs.sol";

contract D4AProtocolTest is DeployHelper {
    MintNftSigUtils public sigUtils;
    bytes32 public daoId;
    IERC20 public token;
    address public daoFeePool;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();

        sigUtils = new MintNftSigUtils(address(protocol));

        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.mintableRound = 50;
        createDaoParam.isBasicDao = true;
        createDaoParam.noPermission = true;
        createDaoParam.selfRewardRatioETH = 5000;
        daoId = _createDaoForFunding(createDaoParam, daoCreator.addr);
        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);

        canvasId = bytes32(uint256(1));
        super._createCanvasAndMintNft(
            daoId,
            canvasId,
            "test token uri 1",
            "test canvas uri 1",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );
    }

    // 方法已取消
    // function test_setCanvasRebateRatioInBps() public { }

    // 方法已取消
    // function test_getCanvasRebateRatioInBps() public { }

    // event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    // 方法已取消
    // function test_setCanvasRebateRatioInBps_ExpectEmit() public { }

    // error NotCanvasOwner();

    // 方法已取消
    // function test_RevertIf_setCanvasRebateRatioInBps_NotCanvasOwner() public { }

    function test_setDaoNftMaxSupply() public {
        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);
        uint256 nftMaxSupply = ID4AProtocolReadable(address(protocol)).getDaoNftMaxSupply(daoId);
        assertEq(nftMaxSupply, maxSupply);
    }

    event DaoNftMaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    function test_setDaoNftMaxSupply_ExpectEmit() public {
        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        vm.expectEmit(address(protocol));
        emit DaoNftMaxSupplySet(daoId, maxSupply);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);
    }

    function test_RevertIf_setDaoNftMaxSupply_NotNftOwner() public {
        uint256 maxSupply = 10;
        vm.expectRevert(NotNftOwner.selector);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);
    }

    error NftExceedMaxAmount();

    function test_RevertIf_ReduceMaxSupplyAndMint() public {
        for (uint256 i; i < 50; i++) {
            string memory tokenUri = string.concat("test token ", vm.toString(i));
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;

            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: mintPrice }(mintNftTransferParam);
        }

        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);

        {
            string memory tokenUri = string.concat("revert test token");
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;

            vm.expectRevert(NftExceedMaxAmount.selector);
            protocol.mintNFT{ value: mintPrice }(mintNftTransferParam);
        }
    }

    function test_ShouldContinueToMintIfIncreaseNftMaxSupply() public {
        for (uint256 i; i < 50; i++) {
            string memory tokenUri = string.concat("test token", vm.toString(i));
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: mintPrice }(mintNftTransferParam);
        }

        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);

        {
            string memory tokenUri = string.concat("revert test token");
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;

            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            vm.expectRevert(NftExceedMaxAmount.selector);
            protocol.mintNFT{ value: mintPrice }(mintNftTransferParam);
        }

        maxSupply = 100;
        startHoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);

        {
            string memory tokenUri = string.concat("test token uri increase supply");
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;

            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: mintPrice }(mintNftTransferParam);
        }
    }

    // MintableRound概念已取消，改为RemainingRound，相关测试方法位于D4AProtocolSetter.t.sol
    // function test_setDaoMintableRound() public {
    // }

    // event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    // function test_setDaoMintableRound_ExpectEmit() public { }

    // function test_RevertIf_setDaoMintableRound_NotDaoOwner() public { }

    // function test_RevertIf_ReduceMintableRoundAndMint() public { }

    // function test_ShouldContinueToMintIfIncreaseMintableRound() public { }

    // function test_createCanvas_ExpectEmit_CanvasRebateRatioInBpsSet() public { }

    function test_claimReward_twice() public {
        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: price }(mintNftTransferParam);
        }

        vm.roll(2);
        protocol.claimDaoCreatorReward(daoId);
        protocol.claimCanvasReward(canvasId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimDaoCreatorReward(daoId);
        protocol.claimCanvasReward(canvasId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
    }

    function test_claimReward_of_old_checkpoint() public {
        {
            vm.roll(2);
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            assertEq(price, 0.005 ether);

            hoax(nftMinter.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: flatPrice }(mintNftTransferParam);
        }

        hoax(daoCreator.addr);
        protocol.setDaoRemainingRound(daoId, 41);

        vm.roll(3);
        (, uint256 rewardETHCreator) = protocol.claimDaoCreatorReward(daoId);
        assertTrue(rewardETHCreator != 0);
        (, uint256 rewardETH) = protocol.claimCanvasReward(canvasId);
        assertTrue(rewardETH != 0);
    }
}

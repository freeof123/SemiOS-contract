// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { NotDaoOwner, ExceedMaxMintableRound } from "contracts/interface/D4AErrors.sol";
import { DeployHelper } from "./utils/DeployHelper.sol";
import { MintNftSigUtils } from "./utils/MintNftSigUtils.sol";

contract D4AProtocolTest is DeployHelper {
    MintNftSigUtils public sigUtils;
    bytes32 public daoId;
    IERC20 public token;
    address public daoFeePool;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();

        sigUtils = new MintNftSigUtils(address(protocol));

        startHoax(daoCreator.addr);
        daoId = _createTrivialDao(0, 50, 0, 0, 750, "test dao uri");
        (address temp,) = protocol.getProjectTokens(daoId);
        token = IERC20(temp);
        (,,, daoFeePool,,,,) = protocol.getProjectInfo(daoId);

        startHoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 0);
    }

    function test_setCanvasRebateRatioInBps() public {
        uint256 ratio = 1000;
        startHoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId, ratio);
        assertEq(protocol.getCanvasRebateRatioInBps(canvasId), ratio);
    }

    function test_getCanvasRebateRatioInBps() public {
        assertEq(protocol.getCanvasRebateRatioInBps(canvasId), 0);
        test_setCanvasRebateRatioInBps();
        assertEq(protocol.getCanvasRebateRatioInBps(canvasId), 1000);
    }

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    function test_setCanvasRebateRatioInBps_ExpectEmit() public {
        uint256 ratio = 1000;
        startHoax(canvasCreator.addr);
        vm.expectEmit(address(protocol));
        emit CanvasRebateRatioInBpsSet(canvasId, ratio);
        protocol.setCanvasRebateRatioInBps(canvasId, ratio);
    }

    error NotCanvasOwner();

    function test_RevertIf_setCanvasRebateRatioInBps_NotCanvasOwner() public {
        uint256 ratio = 1000;
        startHoax(randomGuy.addr);
        vm.expectRevert(NotCanvasOwner.selector);
        protocol.setCanvasRebateRatioInBps(canvasId, ratio);
    }

    function test_setDaoNftMaxSupply() public {
        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        protocol.setDaoNftMaxSupply(daoId, maxSupply);
        (,, uint256 nftMaxSupply,,,,,) = protocol.getProjectInfo(daoId);
        assertEq(nftMaxSupply, maxSupply);
    }

    event DaoNftMaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    function test_setDaoNftMaxSupply_ExpectEmit() public {
        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        vm.expectEmit(address(protocol));
        emit DaoNftMaxSupplySet(daoId, maxSupply);
        protocol.setDaoNftMaxSupply(daoId, maxSupply);
    }

    function test_RevertIf_setDaoNftMaxSupply_NotDaoOwner() public {
        uint256 maxSupply = 10;
        vm.expectRevert(NotDaoOwner.selector);
        protocol.setDaoNftMaxSupply(daoId, maxSupply);
    }

    error NftExceedMaxAmount();

    function test_RevertIf_ReduceMaxSupplyAndMint() public {
        for (uint256 i; i < 50; i++) {
            string memory tokenUri = string.concat("test token uri ", vm.toString(i));
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        protocol.setDaoNftMaxSupply(daoId, maxSupply);

        {
            string memory tokenUri = string.concat("test token uri revert");
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            vm.expectRevert(NftExceedMaxAmount.selector);
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }
    }

    function test_ShouldContinueToMintIfIncreaseNftMaxSupply() public {
        for (uint256 i; i < 50; i++) {
            string memory tokenUri = string.concat("test token uri ", vm.toString(i));
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        uint256 maxSupply = 10;
        startHoax(daoCreator.addr);
        protocol.setDaoNftMaxSupply(daoId, maxSupply);

        {
            string memory tokenUri = string.concat("test token uri revert");
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            vm.expectRevert(NftExceedMaxAmount.selector);
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        maxSupply = 100;
        startHoax(daoCreator.addr);
        protocol.setDaoNftMaxSupply(daoId, maxSupply);

        {
            string memory tokenUri = string.concat("test token uri increase supply");
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }
    }

    function test_setDaoMintableRound() public {
        uint256 round = 10;
        startHoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, round);
        (, uint256 mintableRound,,,,,,) = protocol.getProjectInfo(daoId);
        assertEq(mintableRound, round);
    }

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    function test_setDaoMintableRound_ExpectEmit() public {
        uint256 round = 10;
        startHoax(daoCreator.addr);
        vm.expectEmit(address(protocol));
        emit DaoMintableRoundSet(daoId, round);
        protocol.setDaoMintableRound(daoId, round);
    }

    function test_RevertIf_setDaoMintableRound_NotDaoOwner() public {
        uint256 round = 10;
        vm.expectRevert(NotDaoOwner.selector);
        protocol.setDaoMintableRound(daoId, round);
    }

    function test_RevertIf_ReduceMintableRoundAndMint() public {
        uint256 round = 10;
        startHoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, round);

        for (uint256 i; i < 10; i++) {
            string memory tokenUri = string.concat("test token uri ", vm.toString(i));
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            drb.changeRound(i + 1);
        }

        {
            string memory tokenUri = string.concat("test token uri revert");
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            vm.expectRevert(ExceedMaxMintableRound.selector);
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }
    }

    function test_ShouldContinueToMintIfIncreaseMintableRound() public {
        uint256 round = 10;
        startHoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, round);

        for (uint256 i; i < 10; i++) {
            string memory tokenUri = string.concat("test token uri ", vm.toString(i));
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
            drb.changeRound(i + 1);
        }

        {
            string memory tokenUri = string.concat("test token uri revert");
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            vm.expectRevert(ExceedMaxMintableRound.selector);
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        round = 11;
        startHoax(daoCreator.addr);
        protocol.setDaoMintableRound(daoId, round);

        {
            string memory tokenUri = string.concat("test token uri increase mintable round");
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

            startHoax(nftMinter.addr);
            uint256 mintPrice = flatPrice;
            protocol.mintNFT{ value: mintPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }
    }
}

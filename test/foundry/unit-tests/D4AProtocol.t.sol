// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import { NotDaoOwner, ExceedMaxMintableRound } from "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";

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
        daoId = _createDao(createDaoParam);
        token = IERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId));
        daoFeePool = ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId);

        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 1", new bytes32[](0), 0);
    }

    function test_setCanvasRebateRatioInBps() public {
        uint256 ratio = 1000;
        startHoax(canvasCreator.addr);
        ID4AProtocolSetter(address(protocol)).setCanvasRebateRatioInBps(canvasId, ratio);
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasRebateRatioInBps(canvasId), ratio);
    }

    function test_getCanvasRebateRatioInBps() public {
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasRebateRatioInBps(canvasId), 0);
        test_setCanvasRebateRatioInBps();
        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasRebateRatioInBps(canvasId), 1000);
    }

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    function test_setCanvasRebateRatioInBps_ExpectEmit() public {
        uint256 ratio = 1000;
        startHoax(canvasCreator.addr);
        vm.expectEmit(address(protocol));
        emit CanvasRebateRatioInBpsSet(canvasId, ratio);
        ID4AProtocolSetter(address(protocol)).setCanvasRebateRatioInBps(canvasId, ratio);
    }

    error NotCanvasOwner();

    function test_RevertIf_setCanvasRebateRatioInBps_NotCanvasOwner() public {
        uint256 ratio = 1000;
        startHoax(randomGuy.addr);
        vm.expectRevert(NotCanvasOwner.selector);
        ID4AProtocolSetter(address(protocol)).setCanvasRebateRatioInBps(canvasId, ratio);
    }

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

    function test_RevertIf_setDaoNftMaxSupply_NotDaoOwner() public {
        uint256 maxSupply = 10;
        vm.expectRevert(NotDaoOwner.selector);
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);
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
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);

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
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);

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
        ID4AProtocolSetter(address(protocol)).setDaoNftMaxSupply(daoId, maxSupply);

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
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, round);
        uint256 mintableRound = ID4AProtocolReadable(address(protocol)).getDaoMintableRound(daoId);
        assertEq(mintableRound, round);
    }

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    function test_setDaoMintableRound_ExpectEmit() public {
        uint256 round = 10;
        startHoax(daoCreator.addr);
        vm.expectEmit(address(protocol));
        emit DaoMintableRoundSet(daoId, round);
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, round);
    }

    function test_RevertIf_setDaoMintableRound_NotDaoOwner() public {
        uint256 round = 10;
        vm.expectRevert(NotDaoOwner.selector);
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, round);
    }

    function test_RevertIf_ReduceMintableRoundAndMint() public {
        uint256 round = 10;
        startHoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, round);

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
            drb.changeRound(i + 2);
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
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, round);

        for (uint256 i; i < 10; i++) {
            drb.changeRound(i + 1);
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

        {
            drb.changeRound(11);
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
        drb.changeRound(10);
        startHoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, round);

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

    function test_createCanvas_ExpectEmit_CanvasRebateRatioInBpsSet() public {
        vm.expectEmit(false, false, false, true, address(protocol));
        emit CanvasRebateRatioInBpsSet(canvasId, 0);
        startHoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri 2 ", new bytes32[](0), 0);
    }

    function test_claimReward_twice() public {
        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        drb.changeRound(2);
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
        protocol.claimProjectERC20Reward(daoId);
        protocol.claimCanvasReward(canvasId);
        protocol.claimNftMinterReward(daoId, nftMinter.addr);
    }

    function test_claimReward_of_old_checkpoint() public {
        {
            string memory tokenUri = "test token uri";
            uint256 flatPrice = 0;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
            hoax(nftMinter.addr);
            protocol.mintNFT{ value: price }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
            );
        }

        hoax(daoCreator.addr);
        ID4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 42);

        drb.changeRound(2);
        assertTrue(protocol.claimProjectERC20Reward(daoId) != 0);
        assertTrue(protocol.claimCanvasReward(canvasId) != 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam } from "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";

contract ProtoDaoTestDirectly is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    function test_PDCreateFunding_createBasicDAO() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 existDaoId = bytes32(0);
        bool isBasicDao = true;
        bool uniPriceModeOff = true;
        bool topUpMode = false;
        bytes32 daoId = super._createDaoForFunding(param, existDaoId, false, uniPriceModeOff, 0, isBasicDao, topUpMode);

        uint256 preBalance = daoCreator.addr.balance;

        uint256 flatPrice = 0.01 ether;

        super._mintNftDaoFunding(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            flatPrice,
            daoCreator.key,
            daoCreator.addr
        );

        uint256 balanceDiff = preBalance - daoCreator.addr.balance;

        // l.protocolMintFeeRatioInBps = 250
        assertEq(protocol.protocolFeePool().balance, flatPrice * 250 / 10_000);

        // canvasCreatorMintFeeRatioFiatPrice: 250
        assertEq(balanceDiff, flatPrice * (10_000 - 250) / 10_000);

        // assetPoolMintFeeRatioFiatPrice: 3500
        assertEq(protocol.getDaoAssetPool(daoId).balance, flatPrice * 3500 / 10_000);

        // redeemPoolMintFeeRatioFiatPrice: 6000
        assertEq(protocol.getDaoFeePool(daoId).balance, flatPrice * 6000 / 10_000);
    }

    function test_PDCreateFunding_createBasicDAO_OpenUnifiedPriceWithETH() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 existDaoId = bytes32(0);
        bool isBasicDao = true;
        bool uniPriceModeOff = false;
        bool topUpMode = false;
        bytes32 daoId = super._createDaoForFunding(param, existDaoId, false, uniPriceModeOff, 0, isBasicDao, topUpMode);

        uint256 preBalance = daoCreator.addr.balance;

        uint256 flatPrice = 0.01 ether;

        super._mintNftDaoFunding(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            flatPrice,
            daoCreator.key,
            daoCreator.addr
        );

        uint256 balanceDiff = preBalance - daoCreator.addr.balance;

        // l.protocolMintFeeRatioInBps = 250
        assertEq(protocol.protocolFeePool().balance, flatPrice * 250 / 10_000);

        // canvasCreatorMintFeeRatioFiatPrice: 250
        assertEq(balanceDiff, flatPrice * (10_000 - 250) / 10_000);

        // assetPoolMintFeeRatioFiatPrice: 3500
        assertEq(protocol.getDaoAssetPool(daoId).balance, flatPrice * 3500 / 10_000);

        // redeemPoolMintFeeRatioFiatPrice: 6000
        assertEq(protocol.getDaoFeePool(daoId).balance, flatPrice * 6000 / 10_000);
    }

    function test_PDCreateFunding_createBasicDAO_OpenUnifiedModeWithZeroETH() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 existDaoId = bytes32(0);
        bool isBasicDao = true;
        bool uniPriceModeOff = true;
        bool topUpMode = false;
        bytes32 daoId = super._createDaoForFunding(param, existDaoId, false, uniPriceModeOff, 0, isBasicDao, topUpMode);

        uint256 preBalance = daoCreator.addr.balance;

        super._mintNftDaoFunding(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0,
            daoCreator.key,
            daoCreator.addr
        );

        uint256 balanceDiff = preBalance - daoCreator.addr.balance;

        // l.protocolMintFeeRatioInBps = 250
        assertEq(protocol.protocolFeePool().balance, 0.01 ether * 250 / 10_000);

        // canvasCreatorMintFeeRatio: 750
        assertEq(balanceDiff, 0.01 ether * (10_000 - 750) / 10_000);

        // assetPoolMintFeeRatio: 2000
        assertEq(protocol.getDaoAssetPool(daoId).balance, 0.01 ether * 2000 / 10_000);

        // redeemPoolMintFeeRatio: 7000
        assertEq(protocol.getDaoFeePool(daoId).balance, 0.01 ether * 7000 / 10_000);
    }

    // ==============================================================================

    // function test_PDCreateFunding_createContinuousDAO() public {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     bytes32 existDaoId = bytes32(0);
    //     bool isBasicDao = true;
    //     bytes32 daoId = super._createDaoForFunding(param, existDaoId, false, true, 0, isBasicDao);

    //     param.daoUri = "continuous dao uri";
    //     param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
    //     isBasicDao = false;

    //     bytes32 subDaoId = super._createDaoForFunding(param, daoId, false, true, 0, isBasicDao);
    // }

    // ==============================================================================

    // function test_DaoCreatorMintDefaultGeneratedWorkDirectly() public {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     bytes32 daoId = _createBasicDaoDirectly(param);

    //     assertEq(protocol.getDaoMintableRound(daoId), 60);

    //     address[] memory accounts = new address[](1);
    //     accounts[0] = daoCreator.addr;
    //     _mintNftWithProof(
    //         daoId,
    //         param.canvasId,
    //         string.concat(
    //             tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
    //         ),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr,
    //         getMerkleProof(accounts, daoCreator.addr)
    //     );
    //     assertEq(protocol.protocolFeePool().balance, 0.00025 ether);
    //     assertEq(protocol.getDaoFeePool(daoId).balance, 0.00975 ether);
    //     assertEq(D4AFeePool(payable(protocol.getDaoFeePool(daoId))).turnover(), 0.00975 ether);

    //     drb.changeRound(2);
    //     protocol.claimProjectERC20Reward(daoId);
    //     protocol.claimCanvasReward(param.canvasId);
    //     protocol.claimNftMinterReward(daoId, daoCreator.addr);

    //     IERC20 token = IERC20(protocol.getDaoToken(daoId));
    //     assertEq(token.totalSupply(), 833_333_333_333_333_333_333_333);
    //     assertEq(token.balanceOf(protocol.protocolFeePool()), 16_666_666_666_666_666_666_666);
    //     assertEq(token.balanceOf(daoCreator.addr), 816_666_666_666_666_666_666_665);
    // }

    // function test_NFTHolderNotAllowedToMintAfterFiveMintsDirectly() public {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     bytes32 daoId = _createBasicDaoDirectly(param);

    //     _mintNft(
    //         daoId,
    //         param.canvasId,
    //         string.concat(
    //             tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
    //         ),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr
    //     );
    //     _mintNft(
    //         daoId,
    //         param.canvasId,
    //         string.concat(
    //             tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
    //         ),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr
    //     );
    //     _mintNft(
    //         daoId,
    //         param.canvasId,
    //         string.concat(
    //             tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
    //         ),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr
    //     );
    //     _mintNft(
    //         daoId,
    //         param.canvasId,
    //         string.concat(
    //             tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(4)), ".json"
    //         ),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr
    //     );
    //     _mintNft(
    //         daoId,
    //         param.canvasId,
    //         string.concat(
    //             tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(5)), ".json"
    //         ),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr
    //     );

    //     bytes32 canvasId = param.canvasId;
    //     string memory tokenUri = string.concat(
    //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(6)), ".json"
    //     );
    //     uint256 flatPrice = 0.01 ether;
    //     bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);

    //     // 在新的逻辑中，在以上参数传递的情况下，这个地方应该是可以铸造超过5个的，所以注释掉下面的selector
    //     //同理，不需要注释，
    //     vm.expectRevert(ExceedMinterMaxMintAmount.selector);

    //     vm.prank(daoCreator.addr);
    //     protocol.mintNFT{ value: flatPrice }(
    //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //     );
    // }

    // function test_ERC20ShouldSplitCorrectlyWhenThreeWorksUploadedByTwoAddressesAreMintedInSameRoundDirectly() public
    // {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     bytes32 daoId = _createBasicDaoDirectly(param);

    //     address[] memory accounts = new address[](1);
    //     accounts[0] = daoCreator.addr;
    //     _mintNftWithProof(
    //         daoId,
    //         param.canvasId,
    //         "test token uri 1",
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr,
    //         getMerkleProof(accounts, daoCreator.addr)
    //     );
    //     address nft = protocol.getDaoNft(daoId);
    //     vm.prank(daoCreator.addr);
    //     D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter.addr, 1001);

    //     drb.changeRound(2);

    //     bytes32 canvasId1 = keccak256(abi.encode(canvasCreator.addr, block.timestamp));
    //     bytes32 canvasId2 = keccak256(abi.encode(canvasCreator2.addr, block.timestamp));

    //     {
    //         string memory tokenUri = "test token uri 2";
    //         uint256 flatPrice = 0.01 ether;
    //         bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         hoax(nftMinter.addr);
    //         protocol.createCanvasAndMintNFT{ value: flatPrice }(
    //             daoId,
    //             canvasId1,
    //             "test canvas uri 1",
    //             canvasCreator.addr,
    //             tokenUri,
    //             abi.encodePacked(r, s, v),
    //             0.01 ether,
    //             new bytes32[](0),
    //             address(this)
    //         );
    //     }
    //     {
    //         string memory tokenUri = "test token uri 3";
    //         uint256 flatPrice = 0.01 ether;
    //         bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator2.key, digest);
    //         hoax(nftMinter.addr);
    //         protocol.createCanvasAndMintNFT{ value: flatPrice }(
    //             daoId,
    //             canvasId2,
    //             "test canvas uri 2",
    //             canvasCreator2.addr,
    //             tokenUri,
    //             abi.encodePacked(r, s, v),
    //             0.01 ether,
    //             new bytes32[](0),
    //             address(this)
    //         );
    //     }
    //     _mintNft(daoId, canvasId2, "test token uri 4", 0.01 ether, canvasCreator2.key, nftMinter.addr);

    //     drb.changeRound(3);

    //     protocol.claimProjectERC20Reward(daoId);
    //     protocol.claimCanvasReward(param.canvasId);
    //     protocol.claimCanvasReward(canvasId1);
    //     protocol.claimCanvasReward(canvasId2);
    //     protocol.claimNftMinterReward(daoId, daoCreator.addr);
    //     protocol.claimNftMinterReward(daoId, nftMinter.addr);
    //     IERC20 token = IERC20(protocol.getDaoToken(daoId));
    //     assertEq(token.balanceOf(protocolFeePool.addr), 33_333_333_333_333_333_333_332);
    //     assertEq(token.balanceOf(daoCreator.addr), 1_216_666_666_666_666_666_666_664);
    //     assertEq(token.balanceOf(canvasCreator.addr), 69_444_444_444_444_444_444_444);
    //     assertEq(token.balanceOf(canvasCreator2.addr), 138_888_888_888_888_888_888_888);
    //     assertEq(token.balanceOf(nftMinter.addr), 208_333_333_333_333_333_333_333);
    // }

    // function test_ERC20ShouldSplitCorrectlyWhenFiveWorksUploadedByTwoAddressesAreMintedInSameRoundDirectly() public {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     param.isProgressiveJackpot = true;
    //     bytes32 daoId = _createBasicDaoDirectly(param);

    //     address[] memory accounts = new address[](1);
    //     accounts[0] = daoCreator.addr;
    //     _mintNftWithProof(
    //         daoId,
    //         param.canvasId,
    //         "test token uri 1",
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr,
    //         getMerkleProof(accounts, daoCreator.addr)
    //     );
    //     _mintNftWithProof(
    //         daoId,
    //         param.canvasId,
    //         "test token uri 2",
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr,
    //         getMerkleProof(accounts, daoCreator.addr)
    //     );
    //     address nft = protocol.getDaoNft(daoId);
    //     vm.prank(daoCreator.addr);
    //     D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter.addr, 1001);
    //     vm.prank(daoCreator.addr);
    //     D4AERC721(nft).safeTransferFrom(daoCreator.addr, nftMinter2.addr, 1002);

    //     drb.changeRound(3);

    //     bytes32 canvasId1 = keccak256(abi.encode(canvasCreator.addr, block.timestamp));
    //     bytes32 canvasId2 = keccak256(abi.encode(canvasCreator2.addr, block.timestamp));

    //     {
    //         string memory tokenUri = "test token uri 3";
    //         uint256 flatPrice = 0.01 ether;
    //         bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId1, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         hoax(nftMinter.addr);
    //         protocol.createCanvasAndMintNFT{ value: flatPrice }(
    //             daoId,
    //             canvasId1,
    //             "test canvas uri 1",
    //             canvasCreator.addr,
    //             tokenUri,
    //             abi.encodePacked(r, s, v),
    //             0.01 ether,
    //             new bytes32[](0),
    //             address(this)
    //         );
    //     }
    //     _mintNft(daoId, canvasId1, "test token uri 4", 0.01 ether, canvasCreator.key, nftMinter.addr);
    //     {
    //         string memory tokenUri = "test token uri 5";
    //         uint256 flatPrice = 0.01 ether;
    //         bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId2, tokenUri, flatPrice);
    //         (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator2.key, digest);
    //         hoax(nftMinter.addr);
    //         protocol.createCanvasAndMintNFT{ value: flatPrice }(
    //             daoId,
    //             canvasId2,
    //             "test canvas uri 2",
    //             canvasCreator2.addr,
    //             tokenUri,
    //             abi.encodePacked(r, s, v),
    //             flatPrice,
    //             new bytes32[](0),
    //             address(this)
    //         );
    //     }
    //     _mintNft(daoId, canvasId1, "test token uri 6", 0.01 ether, canvasCreator.key, nftMinter2.addr);
    //     _mintNft(daoId, canvasId2, "test token uri 7", 0.01 ether, canvasCreator2.key, nftMinter2.addr);

    //     drb.changeRound(4);

    //     protocol.claimProjectERC20Reward(daoId);
    //     protocol.claimCanvasReward(param.canvasId);
    //     protocol.claimCanvasReward(canvasId1);
    //     protocol.claimCanvasReward(canvasId2);
    //     protocol.claimNftMinterReward(daoId, daoCreator.addr);
    //     protocol.claimNftMinterReward(daoId, nftMinter.addr);
    //     protocol.claimNftMinterReward(daoId, nftMinter2.addr);
    //     IERC20 token = IERC20(protocol.getDaoToken(daoId));
    //     assertEq(token.balanceOf(protocolFeePool.addr), 49_999_999_999_999_999_999_999);
    //     assertEq(token.balanceOf(daoCreator.addr), 1_616_666_666_666_666_666_666_664);
    //     assertEq(token.balanceOf(canvasCreator.addr), 249_999_999_999_999_999_999_999);
    //     assertEq(token.balanceOf(canvasCreator2.addr), 166_666_666_666_666_666_666_666);
    //     assertEq(token.balanceOf(nftMinter.addr), 249_999_999_999_999_999_999_999);
    //     assertEq(token.balanceOf(nftMinter2.addr), 166_666_666_666_666_666_666_666);
    // }

    // function test_ShouldIncreaseDaoTurnoverAfterTransferETHIntoDaoFeePoolDirectly() public {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     bytes32 daoId = _createBasicDaoDirectly(param);

    //     D4AFeePool daoFeePool = D4AFeePool(payable(protocol.getDaoFeePool(daoId)));
    //     assertEq(daoFeePool.turnover(), 0);
    //     assertEq(protocol.ableToUnlock(daoId), false);

    //     hoax(randomGuy.addr);
    //     (bool succ,) = address(daoFeePool).call{ value: 2 ether }("");
    //     require(succ);

    //     assertEq(daoFeePool.turnover(), 2 ether);
    //     assertEq(protocol.ableToUnlock(daoId), true);
    // }

    // function test_MintWithSameSpecialTokenUriAtTheSameTimeShouldProduceTwoNfts() public {
    //     DeployHelper.CreateDaoParam memory param;
    //     param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
    //     bytes32 daoId = _createBasicDaoDirectly(param);

    //     address[] memory accounts = new address[](1);
    //     accounts[0] = daoCreator.addr;
    //     _mintNftWithProof(
    //         daoId,
    //         param.canvasId,
    //         string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json"),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr,
    //         getMerkleProof(accounts, daoCreator.addr)
    //     );
    //     _mintNftWithProof(
    //         daoId,
    //         param.canvasId,
    //         string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json"),
    //         0.01 ether,
    //         daoCreator.key,
    //         daoCreator.addr,
    //         getMerkleProof(accounts, daoCreator.addr)
    //     );
    //     D4AERC721 nft = D4AERC721(protocol.getDaoNft(daoId));
    //     assertEq(nft.balanceOf(daoCreator.addr), 2);
    //     assertEq(
    //         nft.tokenURI(1), string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1",
    // ".json")
    //     );
    //     assertEq(
    //         nft.tokenURI(2), string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "2",
    // ".json")
    //     );
    // }
}

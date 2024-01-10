// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { IPDProtocolSetter } from "contracts/interface/IPDProtocolSetter.sol";

import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4ASettingsReadable } from "contracts/D4ASettings/D4ASettingsReadable.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";

import { PDProtocolHarness } from "test/foundry/harness/PDProtocolHarness.sol";
import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";

contract MintNftTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_RevertIf_mintNft_when_reward_isProgressiveJackpot_and_exceed_mintable_round() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = false;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.noPermission = true;
        daoId = _createDaoForFunding(param, address(this));
        IPDProtocolSetter(address(protocol)).setDaoRemainingRound(daoId, 10);
        vm.roll(11);
        CreateCanvasAndMintNFTParam memory mintNftTransferParam;
        mintNftTransferParam.daoId = daoId;
        mintNftTransferParam.canvasId = param.canvasId;
        mintNftTransferParam.tokenUri = "nft1";
        mintNftTransferParam.proof = new bytes32[](0);
        mintNftTransferParam.flatPrice = 0.01 ether;
        mintNftTransferParam.nftSignature = hex"11";
        mintNftTransferParam.nftOwner = nftMinter.addr;
        mintNftTransferParam.erc20Signature = "";
        mintNftTransferParam.deadline = 0;
        vm.expectRevert(ExceedMaxMintableRound.selector);
        protocol.mintNFT{ value: 0.01 ether }(mintNftTransferParam);

        // cannot catch the error during minting
        // super._createCanvasAndMintNft(
        //     daoId, canvasId2, "nft1", "canvas2", 0, canvasCreator2.key, canvasCreator2.addr, nftMinter.addr
        // );
    }

    function test_TokenIdShouldStartAtOne() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = false;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.noPermission = true;

        daoId = _createDaoForFunding(param, address(this));

        // hoax(canvasCreator.addr);
        // canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        uint256 tokenId = _createCanvasAndMintNft(
            daoId,
            canvasId,
            "test token uri 1",
            "test canvas uri",
            0.01 ether,
            canvasCreator.key,
            canvasCreator.addr,
            nftMinter.addr
        );
        assertEq(tokenId, 1);
        tokenId = _mintNft(daoId, canvasId, "test token uri 2", 0.01 ether, canvasCreator.key, nftMinter.addr);
        assertEq(tokenId, 2);
        tokenId = _mintNft(daoId, canvasId, "test token uri 3", 0.01 ether, canvasCreator.key, nftMinter.addr);
        assertEq(tokenId, 3);
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function test_mintNFTAndTransfer_UnifiedPriceMintTest() public {
        // 创建一个BasicDao
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = false; // 开启全局一口价
        param.topUpMode = false;
        param.noPermission = true;

        daoId = _createDaoForFunding(param, address(this));

        // MintAndTransfer一个NFT，铸造的NftFlatPrice不等于0.01，签名传空，然后expectRevert
        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );

            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = 0.02 ether;
            mintNftTransferParam.nftSignature = "0x0";
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;

            // 传入一个不是0.01的flatPrice期望revert
            vm.expectRevert(NotBasicDaoNftFlatPrice.selector);
            hoax(daoCreator.addr);
            protocol.mintNFT{ value: 0.02 ether }(mintNftTransferParam);
        }

        // 使用setDaoUnifiedPrice方法更改全局一口价，并测试更改后的价格能够正确铸造
        protocol.setDaoUnifiedPrice(daoId, 0.03 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.03 ether);

        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
            );
            uint256 flatPrice = 0.03 ether;
            vm.expectEmit(protocol.getDaoNft(daoId));
            emit Transfer(address(0), address(nftMinter.addr), 1);
            hoax(daoCreator.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = "0x0";
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: flatPrice }(mintNftTransferParam);
        }

        // 在上面的Dao基础上创建一个延续的Dao, 关闭全局一口价，设置全局一口价0.03 ether
        param.daoUri = "ContinuousDaoUri";
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.uniPriceModeOff = true;
        param.unifiedPrice = 0.03 ether;
        bytes32 continuousDaoId = _createDaoForFunding(param, address(this));
        assertEq(protocol.getDaoUnifiedPrice(continuousDaoId), 0.03 ether);
        assertEq(protocol.getDaoReserveNftNumber(continuousDaoId), 1000);

        // 关闭全局一口价的铸造
        // // 1.关闭全局一口价，SpetialTokenUri，无签名，可以成功铸造
        // {
        //     canvasId = param.canvasId;
        //     string memory tokenUri = string.concat(
        //         tokenUriPrefix,
        //         vm.toString(protocol.getDaoIndex(continuousDaoId)),
        //         "-",
        //         vm.toString(uint256(1)),
        //         ".json"
        //     );
        //     uint256 flatPrice = 0.01 ether;
        //     vm.expectEmit(protocol.getDaoNft(continuousDaoId));
        //     emit Transfer(address(0), address(nftMinter.addr), 1);
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        //     protocol.setDaoFloorPrice(continuousDaoId, 0.02 ether);
        //     vm.expectRevert(NotBasicDaoFloorPrice.selector);
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        //     vm.stopPrank();
        // }

        // // 2.关闭全局一口价，一般TokenUri，无签名。铸造失败（原因："ECDSA: invalid signature length"）
        {
            canvasId = param.canvasId;
            string memory normalTokenUri = "NormalTokenUri";
            uint256 flatPrice = 0.01 ether;
            vm.expectRevert("ECDSA: invalid signature length");
            hoax(daoCreator.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = continuousDaoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = normalTokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = "0x0";
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: flatPrice }(mintNftTransferParam);
        }

        // // 3.关闭全局一口价，格式与SpecialTokenUri相同但是超过预留数量，铸造失败（原因：签名无法验证）
        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix,
                vm.toString(protocol.getDaoIndex(continuousDaoId)),
                "-",
                vm.toString(uint256(1205)),
                ".json"
            );
            uint256 flatPrice = 0.01 ether;
            vm.expectRevert("ECDSA: invalid signature length");
            hoax(daoCreator.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = continuousDaoId;
            mintNftTransferParam.canvasId = canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = "0x0";
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: flatPrice }(mintNftTransferParam);
        }

        // // 创建另一个延续的Dao，开启全局一口价，全局一口价设为0.03 , 预留数量更改为2000
        // param.daoUri = "ContinuousDaoUri2";
        // param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 2));
        // bytes32 continuousDaoId2 = _createContinuousDao(param, daoId, true, false, 2000);
        // (upkeepNeeded, performData) = unlocker.checkUpkeep("");
        // if (upkeepNeeded) {
        //     unlocker.performUpkeep(performData);
        // }
        // hoax(daoCreator.addr);
        // protocol.setDaoUnifiedPrice(continuousDaoId2, 0.03 ether);
        // assertEq(protocol.getDaoUnifiedPrice(continuousDaoId2), 0.03 ether);

        // // 铸造两个预留编号的Dao
        // {
        //     canvasId = param.canvasId;
        //     string memory tokenUri = string.concat(
        //         tokenUriPrefix,
        //         vm.toString(protocol.getDaoIndex(continuousDaoId2)),
        //         "-",
        //         vm.toString(uint256(800)),
        //         ".json"
        //     );
        //     uint256 flatPrice = 0.03 ether;
        //     hoax(daoCreator.addr);
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId2, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        // }

        // // 两个一致的Uri，下一个被创建的将自动编号+1，所以这个地方不报错
        // {
        //     canvasId = param.canvasId;
        //     string memory tokenUri = string.concat(
        //         tokenUriPrefix,
        //         vm.toString(protocol.getDaoIndex(continuousDaoId2)),
        //         "-",
        //         vm.toString(uint256(800)),
        //         ".json"
        //     );
        //     uint256 flatPrice = 0.03 ether;
        //     hoax(daoCreator.addr);
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId2, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        // }

        // // 按照全局一口价铸造，铸造成功
        // {
        //     canvasId = param.canvasId;
        //     string memory normalTokenUri = "ContinuousDao2NormalTokenUri";
        //     uint256 flatPrice = 0.03 ether;
        //     hoax(daoCreator.addr);
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId2, canvasId, normalTokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        // }

        // // 创建另一个延续的Dao，开启全局一口价，全局一口价设为0.03 , 预留数量更改为2000，该Dao用于验证预留以及非预留的TokenId是否正常分配
        // param.daoUri = "ContinuousDaoUri3";
        // param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 3));
        // bytes32 continuousDaoId3 = _createContinuousDao(param, daoId, true, false, 500);
        // (upkeepNeeded, performData) = unlocker.checkUpkeep("");
        // if (upkeepNeeded) {
        //     unlocker.performUpkeep(performData);
        // }
        // hoax(daoCreator.addr);
        // protocol.setDaoUnifiedPrice(continuousDaoId3, 0 ether);
        // assertEq(protocol.getDaoUnifiedPrice(continuousDaoId3), 0.01 ether);
        // {
        //     canvasId = param.canvasId;
        //     string memory tokenUri = string.concat(
        //         tokenUriPrefix,
        //         vm.toString(protocol.getDaoIndex(continuousDaoId3)),
        //         "-",
        //         vm.toString(uint256(200)),
        //         ".json"
        //     );
        //     uint256 flatPrice = 0 ether;
        //     hoax(daoCreator.addr);
        //     vm.expectRevert();
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId3, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        // }

        // //  9999 eth
        // hoax(daoCreator.addr);
        // protocol.setDaoUnifiedPrice(continuousDaoId3, 9999 ether);
        // assertEq(protocol.getDaoUnifiedPrice(continuousDaoId3), 0);
        // {
        //     canvasId = param.canvasId;
        //     string memory tokenUri = string.concat(
        //         tokenUriPrefix,
        //         vm.toString(protocol.getDaoIndex(continuousDaoId3)),
        //         "-",
        //         vm.toString(uint256(201)),
        //         ".json"
        //     );
        //     uint256 flatPrice = 0 ether;
        //     hoax(daoCreator.addr);

        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId3, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        // }

        // {
        //     canvasId = param.canvasId;
        //     string memory normalTokenUri = "ContinuousDao3NormalTokenUri";
        //     uint256 flatPrice = 0 ether;
        //     hoax(daoCreator.addr);
        //     protocol.mintNFTAndTransfer{ value: flatPrice }(
        //         continuousDaoId3, canvasId, normalTokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
        //     );
        // }
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AConstants.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
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

    function test_mintNFT_pay_lower_price_when_canvasRebateRatioInBps_is_set() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.nftMinterERC20RatioInBps = 300;
        createDaoParam.actionType = 16;
        daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: price - price * 6750 * 3000 / BASIS_POINT ** 2 }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_RevertIf_mintNFT_with_too_low_price_when_canvasRebateRatioInBps_is_set() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
        vm.expectRevert(NotEnoughEther.selector);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: price - price * 6750 * 3000 / BASIS_POINT ** 2 - 1 }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_RevertIf_mintNft_when_reward_isProgressiveJackpot_and_exceed_mintable_round() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.isProgressiveJackpot = true;
        daoId = _createDao(createDaoParam);

        drb.changeRound(1);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        drb.changeRound(11);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 10);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        uint256 price = ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId);
        vm.expectRevert(ExceedMaxMintableRound.selector);
        hoax(nftMinter.addr);
        protocol.mintNFT{ value: price }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
    }

    function test_Mint_ETH_Split() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        daoId = _createDao(createDaoParam);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        (,,, address daoFeePool,,,,) = ID4AProtocolReadable(address(protocol)).getProjectInfo(daoId);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setRatio(daoId, 300, 9500, 0, 9750, 9750);

        deal(D4ASettingsReadable(address(protocol)).protocolFeePool(), 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);

        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0.01 ether;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);

        hoax(nftMinter.addr);
        protocol.mintNFT{ value: flatPrice }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        assertEq(D4ASettingsReadable(address(protocol)).protocolFeePool().balance, 0.01 ether * 250 / 10_000);
        assertEq(daoFeePool.balance, 0.01 ether * 9750 / 10_000);
        assertEq(canvasCreator.addr.balance, 0);
    }

    function test_Batch_mint_ETH_Split() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        daoId = _createDao(createDaoParam);
        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        (,,, address daoFeePool,,,,) = ID4AProtocolReadable(address(protocol)).getProjectInfo(daoId);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setRatio(daoId, 300, 9500, 0, 9750, 9750);

        deal(D4ASettingsReadable(address(protocol)).protocolFeePool(), 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);

        MintNftInfo[] memory mintNftInfos = new MintNftInfo[](10);
        bytes[] memory signatures = new bytes[](10);
        uint256 totalPrice;
        for (uint256 i; i < 10; i++) {
            string memory tokenUri = string.concat("test token uri ", vm.toString(i));
            uint256 flatPrice = 0.01 ether * (i + 1);
            totalPrice += flatPrice;
            bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            mintNftInfos[i] = MintNftInfo(tokenUri, flatPrice);
            signatures[i] = abi.encodePacked(r, s, v);
        }

        hoax(nftMinter.addr);
        protocol.batchMint{ value: totalPrice }(daoId, canvasId, new bytes32[](0), mintNftInfos, signatures);
        assertEq(D4ASettingsReadable(address(protocol)).protocolFeePool().balance, totalPrice * 250 / 10_000);
        assertEq(daoFeePool.balance, totalPrice * 9750 / 10_000);
        assertEq(canvasCreator.addr.balance, 0);
    }

    function test_PriceShouldUpdateCorrectlyWhenBatchMintAndLPV() public {
        DeployHelper.CreateDaoParam memory param;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 0.042 ether;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        string[] memory tokenUris = new string[](2);
        tokenUris[0] = "test token uri 1";
        tokenUris[1] = "test token uri 2";
        uint256[] memory flatPrices = new uint256[](2);
        flatPrices[0] = 0;
        flatPrices[1] = 0;
        _batchMint(daoId, canvasId, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.01 ether + 0.042 ether * 2);
    }

    function test_batchMint_ShouldSplitETHCorrectly() public {
        DeployHelper.CreateDaoParam memory param;
        param.daoFeePoolETHRatioInBps = 9750;
        param.daoFeePoolETHRatioInBpsFlatPrice = 9750;
        param.nftMinterERC20RatioInBps = 300;
        param.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        param.priceFactor = 0.6 ether;
        param.floorPriceRank = 2;
        param.actionType = 16;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 2000);

        deal(protocolFeePool.addr, 0);
        address daoFeePool = protocol.getDaoFeePool(daoId);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);

        {
            string[] memory tokenUris = new string[](2);
            tokenUris[0] = "test token uri 1";
            tokenUris[1] = "test token uri 2";
            uint256[] memory flatPrices = new uint256[](2);
            flatPrices[0] = 0;
            flatPrices[1] = 0.5 ether;
            _batchMint(daoId, canvasId, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        }

        assertEq(protocolFeePool.addr.balance, 0.01325 ether);
        assertEq(daoFeePool.balance, 0.51675 ether);
        assertEq(canvasCreator.addr.balance, 0);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.63 ether);

        drb.changeRound(3);

        hoax(daoCreator.addr);
        protocol.setRatio(daoId, 300, 9000, 500, 4750, 5250);
        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 0.6 ether);
        hoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId, 0);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.015 ether);

        deal(protocolFeePool.addr, 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);

        {
            string[] memory tokenUris = new string[](2);
            tokenUris[0] = "test token uri 3";
            tokenUris[1] = "test token uri 4";
            uint256[] memory flatPrices = new uint256[](2);
            flatPrices[0] = 0;
            flatPrices[1] = 0;
            _batchMint(daoId, canvasId, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        }

        assertEq(protocolFeePool.addr.balance, 0.001125 ether);
        assertEq(daoFeePool.balance, 0.021375 ether);
        assertEq(canvasCreator.addr.balance, 0.0225 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.63 ether);

        hoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId, 1e4);

        deal(protocolFeePool.addr, 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);

        {
            string[] memory tokenUris = new string[](2);
            tokenUris[0] = "test token uri 5";
            tokenUris[1] = "test token uri 6";
            uint256[] memory flatPrices = new uint256[](2);
            flatPrices[0] = 0.0301 ether;
            flatPrices[1] = 0.0302 ether;
            _batchMint(daoId, canvasId, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        }

        assertEq(protocolFeePool.addr.balance, 0.0015075 ether);
        assertEq(daoFeePool.balance, 0.0316575 ether);
        assertEq(canvasCreator.addr.balance, 0);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.63 ether);

        drb.changeRound(5);

        hoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId, 0.15e4);

        deal(protocolFeePool.addr, 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);

        {
            string[] memory tokenUris = new string[](4);
            tokenUris[0] = "test token uri 7";
            tokenUris[1] = "test token uri 8";
            tokenUris[2] = "test token uri 9";
            tokenUris[3] = "test token uri 10";
            uint256[] memory flatPrices = new uint256[](4);
            flatPrices[0] = 0.0303 ether;
            flatPrices[1] = 0.0304 ether;
            flatPrices[2] = 0 ether;
            flatPrices[3] = 0 ether;
            _batchMint(daoId, canvasId, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        }

        assertEq(protocolFeePool.addr.balance, 0.0026425 ether);
        assertEq(daoFeePool.balance, 0.0532425 ether);
        assertEq(canvasCreator.addr.balance, 0.04234275 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 0.63 ether);

        hoax(daoCreator.addr);
        protocol.setRatio(daoId, 300, 7500, 2000, 9750, 9750);
        hoax(daoCreator.addr);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 16_000);
        hoax(daoCreator.addr);
        protocol.setDaoFloorPrice(daoId, 1 ether);
        hoax(canvasCreator.addr);
        protocol.setCanvasRebateRatioInBps(canvasId, 0);

        drb.changeRound(7);

        assertEq(protocol.getCanvasNextPrice(canvasId), 0.5 ether);

        deal(protocolFeePool.addr, 0);
        deal(daoFeePool, 0);
        deal(canvasCreator.addr, 0);
        deal(nftMinter.addr, 0);

        {
            string[] memory tokenUris = new string[](2);
            tokenUris[0] = "test token uri 11";
            tokenUris[1] = "test token uri 12";
            uint256[] memory flatPrices = new uint256[](2);
            flatPrices[0] = 0 ether;
            flatPrices[1] = 1.2 ether;
            _batchMint(daoId, canvasId, tokenUris, flatPrices, canvasCreator.key, nftMinter.addr);
        }

        assertEq(protocolFeePool.addr.balance, 0.0425 ether);
        assertEq(daoFeePool.balance, 1.6575 ether);
        assertEq(canvasCreator.addr.balance, 0 ether);
        assertEq(protocol.getCanvasNextPrice(canvasId), 1 ether);
    }

    function test_TokenIdShouldStartAtOne() public {
        DeployHelper.CreateDaoParam memory param;
        daoId = _createDao(param);

        hoax(canvasCreator.addr);
        canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        uint256 tokenId = _mintNft(daoId, canvasId, "test token uri 1", 0, canvasCreator.key, nftMinter.addr);
        assertEq(tokenId, 1);
        tokenId = _mintNft(daoId, canvasId, "test token uri 2", 0, canvasCreator.key, nftMinter.addr);
        assertEq(tokenId, 2);
        tokenId = _mintNft(daoId, canvasId, "test token uri 3", 0, canvasCreator.key, nftMinter.addr);
        assertEq(tokenId, 3);
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function test_mintNFTAndTransfer_UnifiedPriceMintTest() public {
        // 创建一个BasicDao
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        daoId = _createBasicDao(param);

        console2.log("Basic Dao Unified Price Off:", protocol.getDaoUnifiedPriceModeOff(daoId));
        // MintAndTransfer一个NFT，铸造的NftFlatPrice不等于0.01，签名传空，然后expectRevert
        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );

            // 传入一个不是0.01的flatPrice期望revert
            uint256 flatPrice = 0.02 ether;
            vm.expectRevert(NotBasicDaoNftFlatPrice.selector);
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        bool upkeepNeeded;
        bytes memory performData;

        address basicDaoFeePoolAddress = protocol.getDaoFeePool(daoId);
        BasicDaoUnlocker unlocker = new BasicDaoUnlocker(address(protocol));

        (bool success,) = basicDaoFeePoolAddress.call{ value: 3 ether }("");
        assertTrue(success);
        (upkeepNeeded, performData) = unlocker.checkUpkeep("");
        if (upkeepNeeded) {
            unlocker.performUpkeep(performData);
        }

        // 使用setDaoUnifiedPrice方法更改全局一口价，并测试更改后的价格能够正确铸造
        hoax(daoCreator.addr);
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
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        // 在上面的Dao基础上创建一个延续的Dao, 关闭全局一口价，设置全局一口价0.03 ether
        param.daoUri = "ContinuousDaoUri";
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        bytes32 continuousDaoId = _createContinuousDao(param, daoId, true, true, 1000);
        (upkeepNeeded, performData) = unlocker.checkUpkeep("");
        if (upkeepNeeded) {
            unlocker.performUpkeep(performData);
        }
        hoax(daoCreator.addr);
        protocol.setDaoUnifiedPrice(daoId, 0.03 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.03 ether);
        console2.log("Continuous Dao 1 Unified Price Off:", protocol.getDaoUnifiedPriceModeOff(continuousDaoId));
        // 关闭了全局一口价的铸造
        // 1.关闭全局一口价，SpetialTokenUri，无签名，可以成功铸造
        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix,
                vm.toString(protocol.getDaoIndex(continuousDaoId)),
                "-",
                vm.toString(uint256(1)),
                ".json"
            );
            uint256 flatPrice = 0.01 ether;
            vm.expectEmit(protocol.getDaoNft(continuousDaoId));
            emit Transfer(address(0), address(nftMinter.addr), 1);
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        // 2.关闭全局一口价，一般TokenUri，无签名。铸造失败（原因：签名无法验证）
        {
            canvasId = param.canvasId;
            string memory normalTokenUri = "NormalTokenUri";
            uint256 flatPrice = 0.01 ether;
            vm.expectRevert();
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId, canvasId, normalTokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        // 3.关闭全局一口价，格式与SpecialTokenUri相同但是超过预留数量，铸造失败（原因：签名无法验证）
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
            vm.expectRevert();
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        // 创建另一个延续的Dao，开启全局一口价，全局一口价设为0.03 , 预留数量更改为2000
        param.daoUri = "ContinuousDaoUri2";
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 2));
        bytes32 continuousDaoId2 = _createContinuousDao(param, daoId, true, false, 2000);
        (upkeepNeeded, performData) = unlocker.checkUpkeep("");
        if (upkeepNeeded) {
            unlocker.performUpkeep(performData);
        }
        hoax(daoCreator.addr);
        protocol.setDaoUnifiedPrice(continuousDaoId2, 0.03 ether);
        assertEq(protocol.getDaoUnifiedPrice(continuousDaoId2), 0.03 ether);
        console2.log("Continuous Dao 2 Unified Price Off:", protocol.getDaoUnifiedPriceModeOff(continuousDaoId2));
        console2.log("Continuous Dao 2 Reserve NFT number:", protocol.getDaoReserveNftNumber(continuousDaoId2));
        console2.log("Continuous Dao 2 Unified Price:", protocol.getDaoUnifiedPrice(continuousDaoId2));

        // 铸造两个预留编号的Dao
        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix,
                vm.toString(protocol.getDaoIndex(continuousDaoId2)),
                "-",
                vm.toString(uint256(800)),
                ".json"
            );
            uint256 flatPrice = 0.03 ether;
            // vm.expectRevert();
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId2, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix,
                vm.toString(protocol.getDaoIndex(continuousDaoId2)),
                "-",
                vm.toString(uint256(800)),
                ".json"
            );
            uint256 flatPrice = 0.03 ether;
            // vm.expectRevert();
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId2, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        // 按照全局一口价铸造，铸造成功
        {
            canvasId = param.canvasId;
            string memory normalTokenUri = "ContinuousDao2NormalTokenUri";
            uint256 flatPrice = 0.03 ether;
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId2,
                canvasId,
                normalTokenUri,
                new bytes32[](0),
                flatPrice,
                "0x0", // abi.encodePacked(r, s, v)
                nftMinter.addr
            );
        }

        // 创建另一个延续的Dao，开启全局一口价，全局一口价设为0.03 , 预留数量更改为2000
        param.daoUri = "ContinuousDaoUri3";
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp + 3));
        bytes32 continuousDaoId3 = _createContinuousDao(param, daoId, true, false, 500);
        (upkeepNeeded, performData) = unlocker.checkUpkeep("");
        if (upkeepNeeded) {
            unlocker.performUpkeep(performData);
        }
        hoax(daoCreator.addr);
        protocol.setDaoUnifiedPrice(continuousDaoId3, 0.03 ether);
        assertEq(protocol.getDaoUnifiedPrice(continuousDaoId3), 0.03 ether);
        {
            canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix,
                vm.toString(protocol.getDaoIndex(continuousDaoId3)),
                "-",
                vm.toString(uint256(200)),
                ".json"
            );
            uint256 flatPrice = 0.03 ether;
            // vm.expectRevert();
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId3, canvasId, tokenUri, new bytes32[](0), flatPrice, "0x0", nftMinter.addr
            );
        }

        {
            canvasId = param.canvasId;
            string memory normalTokenUri = "ContinuousDao3NormalTokenUri";
            uint256 flatPrice = 0.03 ether;
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                continuousDaoId3,
                canvasId,
                normalTokenUri,
                new bytes32[](0),
                flatPrice,
                "0x0", // abi.encodePacked(r, s, v)
                nftMinter.addr
            );
        }
    }
}

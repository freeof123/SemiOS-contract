// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import "forge-std/Test.sol";

contract PDEditPermission is DeployHelper {
    function setUp() public {
        setUpEnv();
    }
    //start add test case for 1.6
    //--------------------------------------------------

    function test_daoParameterSetControl_generalParameter_noOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.needMintableWork = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        //daoCreator set
        startHoax(daoCreator.addr);
        assertEq(protocol.getDaoRoundMintCap(daoId), 100, "Check A");
        protocol.setRoundMintCap(daoId, 10);
        assertEq(protocol.getDaoRoundMintCap(daoId), 10, "Check B");

        assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000, "Check C");
        protocol.setDaoNftMaxSupply(daoId, 1_000_000);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 1_000_000, "Check D");

        assertEq(protocol.getDaoFloorPrice(daoId), 0.01 ether, "Check E");
        protocol.setDaoFloorPrice(daoId, 1 ether);
        assertEq(protocol.getDaoFloorPrice(daoId), 1 ether, "Check E 2");

        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S");
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 50_000);
        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S1");

        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.01 ether, "Check F");
        protocol.setDaoUnifiedPrice(daoId, 1 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 1 ether, "Check G");

        assertEq(protocol.getDaoRemainingRound(daoId), 60, "Check H");
        protocol.setDaoRemainingRound(daoId, 10);
        assertEq(protocol.getDaoRemainingRound(daoId), 10, "Check I");

        assertEq(protocol.getDaoInfiniteMode(daoId), false, "Check J");
        protocol.changeDaoInfiniteMode(daoId, 1);
        assertEq(protocol.getDaoInfiniteMode(daoId), true, "Check k");

        //transfer nft to randomGuy
        address nft = protocol.getDaoNft(daoId);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        vm.expectRevert(NotNftOwner.selector);
        protocol.setRoundMintCap(daoId, 10);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoNftMaxSupply(daoId, 1_000_000);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoFloorPrice(daoId, 1 ether);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 50_000);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoUnifiedPrice(daoId, 1 ether);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoRemainingRound(daoId, 10);
        vm.expectRevert(NotNftOwner.selector);
        protocol.changeDaoInfiniteMode(daoId, 1);
        vm.stopPrank();

        startHoax(randomGuy.addr);
        assertEq(protocol.getDaoRoundMintCap(daoId), 10, "Check A 1");
        protocol.setRoundMintCap(daoId, 100);
        assertEq(protocol.getDaoRoundMintCap(daoId), 100, "Check B 1");

        assertEq(protocol.getDaoNftMaxSupply(daoId), 1_000_000, "Check C 1");
        protocol.setDaoNftMaxSupply(daoId, 10);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 10, "Check D 1");

        assertEq(protocol.getDaoFloorPrice(daoId), 1 ether, "Check E 3");
        protocol.setDaoFloorPrice(daoId, 0.01 ether);
        assertEq(protocol.getDaoFloorPrice(daoId), 0.01 ether, "Check E 2");

        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S 11");
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10);
        assertEq(protocol.getDaoPriceTemplate(daoId), 0x6021944288cC29D790Ad86526107ed5A63150aAa, "Check S 21");

        assertEq(protocol.getDaoUnifiedPrice(daoId), 1 ether, "Check F 1");
        protocol.setDaoUnifiedPrice(daoId, 0.01 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.01 ether, "Check G 1");

        assertEq(protocol.getDaoInfiniteMode(daoId), true, "Check J 1");
        protocol.changeDaoInfiniteMode(daoId, 10);
        assertEq(protocol.getDaoInfiniteMode(daoId), false, "Check k 1");

        assertEq(protocol.getDaoRemainingRound(daoId), 10, "Check H 1");
        protocol.setDaoRemainingRound(daoId, 60);
        assertEq(protocol.getDaoRemainingRound(daoId), 60, "Check I 1");
        vm.stopPrank();
        // protocol.setDaoEditParamPermission(daoId, 0x123, 1);

        //setDaoParams
        //setChildren
        //setRatio
    }

    function test_daoParameterSetControl_setDaoParams_noOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.needMintableWork = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        // daoCreator set
        // startHoax(daoCreator.addr);

        //setDaoParams
        //setChildren
        //setRatio
        bytes32[] memory zeroBytes32Array = new bytes32[](0);
        uint256[] memory zeroUintArray = new uint256[](0);
        SetDaoParam memory vars;
        vars.daoId = daoId;
        vars.nftMaxSupplyRank = 0;
        vars.remainingRound = 1;
        vars.daoFloorPrice = 0.03 ether;
        vars.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        vars.nftPriceFactor = 1000;
        vars.dailyMintCap = 100;
        vars.unifiedPrice = 1006;
        vars.setChildrenParam = SetChildrenParam(zeroBytes32Array, zeroUintArray, zeroUintArray, 0, 0, 0);
        vars.allRatioParam = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000);
        hoax(daoCreator.addr);
        protocol.setDaoParams(vars);

        address nft = protocol.getDaoNft(daoId);
        hoax(daoCreator.addr);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoParams(vars);

        vars.allRatioParam = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 700, 2100, 7000);
        hoax(randomGuy.addr);
        protocol.setDaoParams(vars);
    }

    function test_daoParameterSetControl_setChildrenParam_noOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.needMintableWork = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        // daoCreator set
        // startHoax(daoCreator.addr);

        //setDaoParams
        //setChildren
        //setRatio
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.daoUri = "test dao2 uri";
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        SetChildrenParam memory vars;
        vars.childrenDaoId = new bytes32[](1);
        vars.childrenDaoId[0] = daoId2;
        vars.erc20Ratios = new uint256[](1);
        vars.erc20Ratios[0] = 5000;
        vars.ethRatios = new uint256[](1);
        vars.ethRatios[0] = 5000;
        vars.selfRewardRatioERC20 = 5000;
        vars.selfRewardRatioETH = 5000;

        vm.prank(daoCreator.addr);
        protocol.setChildren(daoId, vars);

        address nft = protocol.getDaoNft(daoId);
        hoax(daoCreator.addr);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setChildren(daoId, vars);

        vars.erc20Ratios[0] = 6000;
        vars.selfRewardRatioERC20 = 4000;
        hoax(randomGuy.addr);
        protocol.setChildren(daoId, vars);
    }

    function test_daoParameterSetControl_setRatioParam_noOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.needMintableWork = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        // daoCreator set
        // startHoax(daoCreator.addr);
        AllRatioParam memory vars = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 5000, 2000, 2800, 5000, 2000, 2800);
        hoax(daoCreator.addr);
        protocol.setRatio(daoId, vars);

        address nft = protocol.getDaoNft(daoId);
        hoax(daoCreator.addr);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setRatio(daoId, vars);

        vars = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 5000, 2000, 2800, 5000, 1000, 3800);
        hoax(randomGuy.addr);
        protocol.setRatio(daoId, vars);
    }

    function test_daoStrategySetControl_setWhitelistMintCap_noOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        (, Whitelist memory whitelist, Blacklist memory blacklist) = super._generateTrivialPermission();

        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam(protocolOwner.addr, 100);
        userMintCapParams[1] = UserMintCapParam(randomGuy.addr, 200);

        hoax(daoCreator.addr);
        protocol.setMintCapAndPermission(
            daoId,
            100,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );

        address nft = protocol.getDaoNft(daoId);
        hoax(daoCreator.addr);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setMintCapAndPermission(
            daoId,
            10,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );

        hoax(randomGuy.addr);
        protocol.setMintCapAndPermission(
            daoId,
            20,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );
    }

    function test_daoStrategySetControl_setMintCapAndPermission_noOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        hoax(daoCreator.addr);
        protocol.setWhitelistMintCap(daoId, randomGuy.addr, 100);

        address nft = protocol.getDaoNft(daoId);
        hoax(daoCreator.addr);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 0);

        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setWhitelistMintCap(daoId, randomGuy.addr, 100);

        hoax(randomGuy.addr);
        protocol.setWhitelistMintCap(daoId, randomGuy.addr, 100);
    }

    function test_daoParameterSetControl_daoStrategySetControl_addOtherNFT() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.needMintableWork = true;
        param.noPermission = true;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);
        //First Part: daoParameterSetControl_generalParameter
        //daoCreator set
        startHoax(daoCreator.addr);
        _testERC721.mint(daoCreator.addr, 100);
        address nft = address(_testERC721);
        protocol.setDaoEditParamPermission(daoId, nft, 100);
        IERC721(nft).safeTransferFrom(daoCreator.addr, randomGuy.addr, 100);

        vm.expectRevert(NotNftOwner.selector);
        protocol.setRoundMintCap(daoId, 10);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoNftMaxSupply(daoId, 1_000_000);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoFloorPrice(daoId, 1 ether);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.EXPONENTIAL_PRICE_VARIATION, 50_000);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoUnifiedPrice(daoId, 1 ether);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoRemainingRound(daoId, 10);
        vm.expectRevert(NotNftOwner.selector);
        protocol.changeDaoInfiniteMode(daoId, 1);

        startHoax(randomGuy.addr);
        assertEq(protocol.getDaoRoundMintCap(daoId), 100, "Check A 1");
        protocol.setRoundMintCap(daoId, 10);
        assertEq(protocol.getDaoRoundMintCap(daoId), 10, "Check B 1");

        assertEq(protocol.getDaoNftMaxSupply(daoId), 10_000, "Check C 1");
        protocol.setDaoNftMaxSupply(daoId, 10);
        assertEq(protocol.getDaoNftMaxSupply(daoId), 10, "Check D 1");

        assertEq(protocol.getDaoFloorPrice(daoId), 0.01 ether, "Check E 3");
        protocol.setDaoFloorPrice(daoId, 1 ether);
        assertEq(protocol.getDaoFloorPrice(daoId), 1 ether, "Check E 2");

        assertEq(protocol.getDaoPriceTemplate(daoId), 0x601b9F4f6Be05d5EDc57165dEC27C0F461A0C94a, "Check S 11");
        protocol.setDaoPriceTemplate(daoId, PriceTemplateType.LINEAR_PRICE_VARIATION, 10);
        assertEq(protocol.getDaoPriceTemplate(daoId), 0x6021944288cC29D790Ad86526107ed5A63150aAa, "Check S 21");

        assertEq(protocol.getDaoUnifiedPrice(daoId), 0.01 ether, "Check F 1");
        protocol.setDaoUnifiedPrice(daoId, 1 ether);
        assertEq(protocol.getDaoUnifiedPrice(daoId), 1 ether, "Check G 1");

        assertEq(protocol.getDaoInfiniteMode(daoId), false, "Check J 1");
        protocol.changeDaoInfiniteMode(daoId, 10);
        assertEq(protocol.getDaoInfiniteMode(daoId), true, "Check k 1");

        assertEq(protocol.getDaoRemainingRound(daoId), 1, "Check H 1");
        protocol.changeDaoInfiniteMode(daoId, 1);
        protocol.setDaoRemainingRound(daoId, 60);
        assertEq(protocol.getDaoRemainingRound(daoId), 60, "Check I 1");
        vm.stopPrank();

        //Seconf part: daoParameterSetControl_setDaoParams
        bytes32[] memory zeroBytes32Array = new bytes32[](0);
        uint256[] memory zeroUintArray = new uint256[](0);
        SetDaoParam memory vars;
        vars.daoId = daoId;
        vars.nftMaxSupplyRank = 0;
        vars.remainingRound = 1;
        vars.daoFloorPrice = 0.03 ether;
        vars.priceTemplateType = PriceTemplateType.LINEAR_PRICE_VARIATION;
        vars.nftPriceFactor = 1000;
        vars.dailyMintCap = 100;
        vars.unifiedPrice = 1006;
        vars.setChildrenParam = SetChildrenParam(zeroBytes32Array, zeroUintArray, zeroUintArray, 0, 0, 0);
        vars.allRatioParam = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000);

        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setDaoParams(vars);

        vm.prank(randomGuy.addr);
        protocol.setDaoParams(vars);

        //Third Part: daoParameterSetControl_setChildrenParam
        param.isBasicDao = false;
        param.existDaoId = daoId;
        param.daoUri = "test dao2 uri";
        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        bytes32 daoId2 = super._createDaoForFunding(param, daoCreator2.addr);
        SetChildrenParam memory vars2;
        vars2.childrenDaoId = new bytes32[](1);
        vars2.childrenDaoId[0] = daoId2;
        vars2.erc20Ratios = new uint256[](1);
        vars2.erc20Ratios[0] = 5000;
        vars2.ethRatios = new uint256[](1);
        vars2.ethRatios[0] = 5000;
        vars2.selfRewardRatioERC20 = 5000;
        vars2.selfRewardRatioETH = 5000;

        hoax(daoCreator2.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setChildren(daoId, vars2);

        vm.prank(randomGuy.addr);
        protocol.setChildren(daoId, vars2);

        //Forth Part: daoParameterSetControl_setRatioParam
        AllRatioParam memory vars3 = AllRatioParam(750, 2000, 7000, 250, 3500, 6000, 5000, 2000, 2800, 5000, 2000, 2800);
        hoax(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setRatio(daoId, vars3);

        vm.prank(randomGuy.addr);
        protocol.setRatio(daoId, vars3);

        //new ------------------------------------------     ------------------------------------------
        //Sixth Part, only can set parameter. no other
        (, Whitelist memory whitelist, Blacklist memory blacklist) = super._generateTrivialPermission();

        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam(protocolOwner.addr, 100);
        userMintCapParams[1] = UserMintCapParam(randomGuy.addr, 200);

        vm.prank(randomGuy.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setMintCapAndPermission(
            daoId,
            100,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );

        hoax(daoCreator.addr);
        protocol.setMintCapAndPermission(
            daoId,
            100,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );

        vm.prank(daoCreator2.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setMintCapAndPermission(
            daoId,
            100,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );

        _testERC721.mint(daoCreator2.addr, 1000);
        hoax(daoCreator.addr);
        protocol.setDaoEditStrategyPermission(daoId, address(_testERC721), 1000);

        vm.prank(daoCreator2.addr);
        protocol.setMintCapAndPermission(
            daoId,
            100,
            userMintCapParams,
            new NftMinterCapInfo[](0),
            new NftMinterCapIdInfo[](0),
            whitelist,
            blacklist,
            blacklist
        );

        vm.prank(daoCreator.addr);
        vm.expectRevert(NotNftOwner.selector);
        protocol.setWhitelistMintCap(daoId, randomGuy.addr, 100);

        vm.prank(daoCreator2.addr);
        protocol.setWhitelistMintCap(daoId, randomGuy.addr, 100);
    }
    //--------------------------------------------------
    //end add test case for 1.6
}

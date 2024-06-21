// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { PDProtocolHarness } from "test/foundry/harness/PDProtocolHarness.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import "contracts/interface/D4AStructs.sol";

import { D4AERC721 } from "contracts/D4AERC721.sol";
import { console2 } from "forge-std/console2.sol";
import "contracts/interface/D4AErrors.sol";

contract PDProtocolTest is DeployHelper {
    function setUp() public {
        setUpEnv();
        PDProtocolHarness temp = new PDProtocolHarness();
        vm.etch(address(protocolImpl), address(temp).code);
    }

    function test_exposed_isSpecialTokenUri() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertTrue(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", vm.toString(uint256(1)), ".json")
            )
        );

        assertTrue(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", vm.toString(uint256(1000)), ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_ExceedDefaultNftNumber() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "0", ".json")
            )
        );
        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "1001", ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_NotValidNumber() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "test", ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_WrongPrefix() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        string memory wrongPrefix = tokenUriPrefix;
        bytes(wrongPrefix)[1] = "a";

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(wrongPrefix, vm.toString(daoIndex), "-", "999", ".json")
            )
        );
    }

    event D4AMintNFT(
        bytes32 daoId, bytes32 canvasId, uint256 tokenId, string tokenUri, uint256 price, NftIdentifier nft
    );

    function test_mintNFT_SpecialTokenUriShouldAbideByTokenId() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.priceTemplateType = PriceTemplateType.EXPONENTIAL_PRICE_VARIATION;
        // param.priceFactor = 1.4e4;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        uint256 daoIndex = protocol.getDaoIndex(daoId);
        address nft = address(_testERC721);
        _testERC721.mint(daoCreator.addr, 0);

        string memory tokenUri = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "1", ".json");
        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;

        vm.expectEmit(address(protocol));
        emit D4AMintNFT(
            daoId, param.canvasId, 1, tokenUri, 0.1 ether, NftIdentifier({ erc721Address: nft, tokenId: 0 })
        );

        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = param.canvasId;
        nftParam.tokenUri = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "999", ".json");
        nftParam.flatPrice = 0.1 ether;
        nftParam.proof = getMerkleProof(accounts, daoCreator.addr);
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.nftIdentifier = NftIdentifier({ erc721Address: nft, tokenId: 0 });
        uint256 tokenId = super._mintNftWithParam(nftParam, daoCreator.addr);

        nft = protocol.getDaoNft(daoId);
        assertEq(D4AERC721(nft).tokenURI(tokenId), tokenUri, "CHECK A");
    }

    function test_mintNFTAndTransfer() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        {
            bytes32 canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            hoax(daoCreator.addr);
            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = param.canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: flatPrice }(mintNftTransferParam);
        }
        address nft = protocol.getDaoNft(daoId);
        assertEq(D4AERC721(nft).ownerOf(1), nftMinter.addr);
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function test_mintNFTAndTransfer_ExpectEmit() public {
        CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.uniPriceModeOff = true;
        param.topUpMode = false;
        param.isProgressiveJackpot = true;
        param.needMintableWork = true;
        param.noPermission = true;
        param.floorPrice = 0.1 ether;
        bytes32 daoId = _createDaoForFunding(param, daoCreator.addr);

        {
            bytes32 canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );
            uint256 flatPrice = 0.1 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            vm.expectEmit(protocol.getDaoNft(daoId));
            emit Transfer(address(0), address(nftMinter.addr), 1);
            hoax(daoCreator.addr);

            CreateCanvasAndMintNFTParam memory mintNftTransferParam;
            mintNftTransferParam.daoId = daoId;
            mintNftTransferParam.canvasId = param.canvasId;
            mintNftTransferParam.tokenUri = tokenUri;
            mintNftTransferParam.proof = new bytes32[](0);
            mintNftTransferParam.flatPrice = flatPrice;
            mintNftTransferParam.nftSignature = abi.encodePacked(r, s, v);
            mintNftTransferParam.nftOwner = nftMinter.addr;
            mintNftTransferParam.erc20Signature = "";
            mintNftTransferParam.deadline = 0;
            protocol.mintNFT{ value: flatPrice }(mintNftTransferParam);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { PDProtocolHarness } from "test/foundry/harness/PDProtocolHarness.sol";
import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";

import { PDCreateProjectProxy } from "contracts/proxy/PDCreateProjectProxy.sol";
import { PDCreate } from "contracts/PDCreate.sol";
import "contracts/interface/D4AStructs.sol";

import { D4AERC721 } from "contracts/D4AERC721.sol";
import { console2 } from "forge-std/Console2.sol";
import "contracts/interface/D4AErrors.sol";

contract PDProtocolTest is DeployHelper {
    function setUp() public {
        setUpEnv();
        PDProtocolHarness temp = new PDProtocolHarness();
        vm.etch(address(protocolImpl), address(temp).code);
    }

    function test_exposed_isSpecialTokenUri() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

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
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

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
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "test", ".json")
            )
        );
    }

    function test_exposed_isSpecialTokenUri_WrongPrefix() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);

        string memory wrongPrefix = tokenUriPrefix;
        bytes(wrongPrefix)[1] = "a";

        assertFalse(
            PDProtocolHarness(address(protocol)).exposed_isSpecialTokenUri(
                daoId, string.concat(wrongPrefix, vm.toString(daoIndex), "-", "999", ".json")
            )
        );
    }

    event D4AMintNFT(bytes32 daoId, bytes32 canvasId, uint256 tokenId, string tokenUri, uint256 price);

    function test_mintNFT_SpecialTokenUriShouldAbideByTokenId() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);
        address nft = protocol.getDaoNft(daoId);
        string memory tokenUri = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "1", ".json");
        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;

        vm.expectEmit(address(protocol));
        emit D4AMintNFT(daoId, param.canvasId, 1, tokenUri, 0.01 ether);
        uint256 tokenId = _mintNftWithProof(
            daoId,
            param.canvasId,
            string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "999", ".json"),
            0.01 ether,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        assertEq(D4AERC721(nft).tokenURI(tokenId), tokenUri);
    }

    function test_batchMint_SpecialTokenUriShouldAbideByTokenId() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        uint256 daoIndex = protocol.getDaoIndex(daoId);
        address nft = protocol.getDaoNft(daoId);
        string memory tokenUri1 = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "1", ".json");
        string memory tokenUri2 = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "2", ".json");

        string[] memory tokenUris = new string[](2);
        tokenUris[0] = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "999", ".json");
        tokenUris[1] = string.concat(tokenUriPrefix, vm.toString(daoIndex), "-", "666", ".json");
        uint256[] memory flatPrices = new uint256[](2);
        flatPrices[0] = 0.01 ether;
        flatPrices[1] = 0.01 ether;

        address[] memory accounts = new address[](1);
        accounts[0] = daoCreator.addr;

        vm.expectEmit(address(protocol));
        emit D4AMintNFT(daoId, param.canvasId, 1, tokenUri1, 0.01 ether);
        vm.expectEmit(address(protocol));
        emit D4AMintNFT(daoId, param.canvasId, 2, tokenUri2, 0.01 ether);
        uint256[] memory tokenIds = _batchMintWithProof(
            daoId,
            param.canvasId,
            tokenUris,
            flatPrices,
            daoCreator.key,
            daoCreator.addr,
            getMerkleProof(accounts, daoCreator.addr)
        );
        assertEq(D4AERC721(nft).tokenURI(tokenIds[0]), tokenUri1);
        assertEq(D4AERC721(nft).tokenURI(tokenIds[1]), tokenUri2);
    }

    function test_mintNFTAndTransfer() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        {
            bytes32 canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v), nftMinter.addr
            );
        }
        address nft = protocol.getDaoNft(daoId);
        assertEq(D4AERC721(nft).ownerOf(1), nftMinter.addr);
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function test_mintNFTAndTransfer_ExpectEmit() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 daoId = _createBasicDao(param);

        {
            bytes32 canvasId = param.canvasId;
            string memory tokenUri = string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
            );
            uint256 flatPrice = 0.01 ether;
            bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);
            vm.expectEmit(protocol.getDaoNft(daoId));
            emit Transfer(address(0), address(nftMinter.addr), 1);
            hoax(daoCreator.addr);
            protocol.mintNFTAndTransfer{ value: flatPrice }(
                daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v), nftMinter.addr
            );
        }
    }

    event CreateContinuousProjectParamEmitted(
        bytes32 existDaoId,
        bytes32 daoId,
        uint256 dailyMintCap,
        bool needMintableWork,
        bool unifiedPriceModeOff,
        uint256 unifiedPrice,
        uint256 reserveNftNumber
    );

    function test_createBasicDaoEvent() public {
        // init create dao param
        DeployHelper.CreateDaoParam memory createDaoParam;
        {
            bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
            createDaoParam.canvasId = canvasId;
        }
        createDaoParam.projectIndex = 42;
        DaoMintCapParam memory daoMintCapParam;
        {
            uint256 length = createDaoParam.minters.length;
            daoMintCapParam.userMintCapParams = new UserMintCapParam[](length + 1);
            for (uint256 i; i < length;) {
                daoMintCapParam.userMintCapParams[i].minter = createDaoParam.minters[i];
                daoMintCapParam.userMintCapParams[i].mintCap = uint32(createDaoParam.userMintCaps[i]);
                unchecked {
                    ++i;
                }
            }
            daoMintCapParam.userMintCapParams[length].minter = daoCreator.addr;
            daoMintCapParam.userMintCapParams[length].mintCap = 5;
            daoMintCapParam.daoMintCap = uint32(createDaoParam.mintCap);
        }

        address[] memory minters = new address[](1);
        minters[0] = daoCreator.addr;
        createDaoParam.minterMerkleRoot = getMerkleRoot(minters);

        bytes memory datas = abi.encodeCall(
            PDCreate.createBasicDao,
            (
                DaoMetadataParam({
                    startDrb: drb.currentRound(),
                    mintableRounds: 60,
                    floorPriceRank: 0,
                    maxNftRank: 2,
                    royaltyFee: 1250,
                    projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
                    projectIndex: createDaoParam.projectIndex
                }),
                BasicDaoParam({
                    initTokenSupplyRatio: 500,
                    canvasId: createDaoParam.canvasId,
                    canvasUri: "test dao creator canvas uri",
                    daoName: "test dao"
                })
            )
        );

        bytes32 _daoId = keccak256(abi.encodePacked(block.number, address(daoProxy), datas, msg.sender));

        vm.expectEmit();
        emit CreateContinuousProjectParamEmitted(_daoId, _daoId, 10_000, true, false, 0.01 ether, 1000);

        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createBasicDao(
            DaoMetadataParam({
                startDrb: drb.currentRound(),
                mintableRounds: 60,
                floorPriceRank: 0,
                maxNftRank: 2,
                royaltyFee: 1250,
                projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
                projectIndex: createDaoParam.projectIndex
            }),
            Whitelist({
                minterMerkleRoot: createDaoParam.minterMerkleRoot,
                minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
                canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
                canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses
            }),
            Blacklist({
                minterAccounts: createDaoParam.minterAccounts,
                canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
            }),
            daoMintCapParam,
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: 4800,
                canvasCreatorERC20Ratio: 2500,
                nftMinterERC20Ratio: 2500,
                daoFeePoolETHRatio: 9750,
                daoFeePoolETHRatioFlatPrice: 9750
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                isProgressiveJackpot: true
            }),
            BasicDaoParam({
                initTokenSupplyRatio: 500,
                canvasId: createDaoParam.canvasId,
                canvasUri: "test dao creator canvas uri",
                daoName: "test dao"
            }),
            20
        );
        assertEq(_daoId, daoId);
    }

    /**
     * @dev expect succeed when invoking createContinuousDao with arg (needMintableWork = false, reserveNftNumber = 0)
     */
    function test_createContinuousDao_needMintableWork_reserveNftNumber() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        createDaoParam.canvasId = canvasId;
        bytes32 daoId = super._createBasicDao(createDaoParam);
        bytes32 canvasId2 = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        createDaoParam.canvasId = canvasId2;
        createDaoParam.daoUri = "continuous dao";
        bool uniPriceModeOff = false;
        uint256 reserveNftNumber = 0;

        super._createContinuousDao(createDaoParam, daoId, false, uniPriceModeOff, reserveNftNumber);
    }

    /**
     * @dev expect revert when invoking createContinuousDao with arg (needMintableWork = true, reserveNftNumber = 0)
     */
    function testFail_createContinuousDao_needMintableWork_reserveNftNumber() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        bytes32 canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        createDaoParam.canvasId = canvasId;
        bytes32 daoId = super._createBasicDao(createDaoParam);
        bytes32 canvasId2 = keccak256(abi.encode(daoCreator.addr, block.timestamp + 1));
        createDaoParam.canvasId = canvasId2;
        createDaoParam.daoUri = "continuous dao";
        bool uniPriceModeOff = false;
        uint256 reserveNftNumber = 0;

        vm.expectRevert(ZeroNftReserveNumber.selector);
        super._createContinuousDao(createDaoParam, daoId, true, uniPriceModeOff, reserveNftNumber);
    }
}

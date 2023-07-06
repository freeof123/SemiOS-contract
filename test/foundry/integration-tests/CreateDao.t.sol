// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import { PriceTemplateType, RewardTemplateType } from "contracts/interface/D4AEnums.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";

contract CreateDaoTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_createDao_With_zero_floor_price() public {
        hoax(daoCreator.addr);
        bytes32 daoId = _createTrivialDao(0, 30, 9999, 0, 750, "test project uri");

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);
        string memory tokenUri = "test nft uri";
        MintNftSigUtils sigUtils = new MintNftSigUtils(address(protocol));
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, 0);

        bytes memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
            signature = bytes.concat(r, s, bytes1(v));
        }

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0);

        hoax(nftMinter.addr);
        protocol.mintNFT(daoId, canvasId, tokenUri, new bytes32[](0), 0, signature);

        assertEq(ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0);
    }

    function test_createDao_With_complex_params() public {
        UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](2);
        userMintCapParams[0] = UserMintCapParam({ minter: daoCreator.addr, mintCap: 1 });
        userMintCapParams[1] = UserMintCapParam({ minter: canvasCreator.addr, mintCap: 2 });
        hoax(operationRoleMember.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 30,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 950,
                projectUri: "test dao uri",
                projectIndex: 42
            }),
            Whitelist({
                minterMerkleRoot: bytes32(0),
                minterNFTHolderPasses: new address[](0),
                canvasCreatorMerkleRoot: bytes32(0),
                canvasCreatorNFTHolderPasses: new address[](0)
            }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            DaoMintCapParam({ daoMintCap: 5, userMintCapParams: userMintCapParams }),
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: 1000,
                canvasCreatorERC20Ratio: 3000,
                nftMinterERC20Ratio: 5800,
                daoFeePoolETHRatio: 3500,
                daoFeePoolETHRatioFlatPrice: 4200
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.LINEAR_PRICE_VARIATION,
                priceFactor: 0.5 ether,
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 15_000,
                rewardDecayLife: 3,
                isProgressiveJackpot: true
            }),
            0x1 | 0x2 | 0x4 | 0x8 | 0x10
        );
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoStartRound(daoId), 1);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoMintableRound(daoId), 30);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoIndex(daoId), 42);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoUri(daoId), "test dao uri");
        assertTrue(ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId) != address(0));
        assertEq(D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).name(), "D4A Token for No.42");
        assertEq(D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).symbol(), "D4A.T42");
        assertEq(D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).decimals(), 18);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId), 1e9 ether);
        assertEq(D4AERC721(ID4AProtocolReadable(address(protocol)).getDaoNft(daoId)).name(), "D4A NFT for No.42");
        assertEq(D4AERC721(ID4AProtocolReadable(address(protocol)).getDaoNft(daoId)).symbol(), "D4A.N42");
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoNftMaxSupply(daoId), 1000);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoNftTotalSupply(daoId), 0);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoNftRoyaltyFeeRatioInBps(daoId), 950);
        assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1), 113_071_951_744_937_526_928_048_255);
        assertEq(
            ID4AProtocolReadable(address(protocol)).getDaoPriceTemplate(daoId),
            ID4ASettingsReadable(address(protocol)).getPriceTemplates()[1]
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getDaoRewardTemplate(daoId),
            ID4ASettingsReadable(address(protocol)).getRewardTemplates()[1]
        );
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoMintCap(daoId), 5);
        (uint32 userMinted, uint32 userMintCap) =
            ID4AProtocolReadable(address(protocol)).getUserMintInfo(daoId, daoCreator.addr);
        assertEq(userMintCap, 1);
        assertEq(userMinted, 0);
        (userMinted, userMintCap) = ID4AProtocolReadable(address(protocol)).getUserMintInfo(daoId, canvasCreator.addr);
        assertEq(userMintCap, 2);
        assertEq(userMinted, 0);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoCanvases(daoId).length, 0);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoPriceFactor(daoId), 0.5 ether);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoFeePoolETHRatio(daoId), 3500);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoFeePoolETHRatioFlatPrice(daoId), 4200);
    }

    function test_createDao_With_trivial_params() public {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 30,
                floorPriceRank: 0,
                maxNftRank: 0,
                royaltyFee: 750,
                projectUri: "test dao uri",
                projectIndex: 0
            }),
            Whitelist({
                minterMerkleRoot: bytes32(0),
                minterNFTHolderPasses: new address[](0),
                canvasCreatorMerkleRoot: bytes32(0),
                canvasCreatorNFTHolderPasses: new address[](0)
            }),
            Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam({
                daoCreatorERC20Ratio: 300,
                canvasCreatorERC20Ratio: 9500,
                nftMinterERC20Ratio: 3000,
                daoFeePoolETHRatio: 3000,
                daoFeePoolETHRatioFlatPrice: 3500
            }),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            0
        );
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoStartRound(daoId), 1);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoMintableRound(daoId), 30);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoIndex(daoId), 110);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoUri(daoId), "test dao uri");
        assertTrue(ID4AProtocolReadable(address(protocol)).getDaoFeePool(daoId) != address(0));
        assertEq(D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).name(), "D4A Token for No.110");
        assertEq(D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).symbol(), "D4A.T110");
        assertEq(D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).decimals(), 18);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId), 1e9 ether);
        assertEq(D4AERC721(ID4AProtocolReadable(address(protocol)).getDaoNft(daoId)).name(), "D4A NFT for No.110");
        assertEq(D4AERC721(ID4AProtocolReadable(address(protocol)).getDaoNft(daoId)).symbol(), "D4A.N110");
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoNftMaxSupply(daoId), 1000);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoNftTotalSupply(daoId), 0);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoNftRoyaltyFeeRatioInBps(daoId), 750);
        assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1), uint256(1e9 ether) / 30);
        assertEq(
            ID4AProtocolReadable(address(protocol)).getDaoPriceTemplate(daoId),
            ID4ASettingsReadable(address(protocol)).getPriceTemplates()[0]
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getDaoRewardTemplate(daoId),
            ID4ASettingsReadable(address(protocol)).getRewardTemplates()[0]
        );
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoMintCap(daoId), 0);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoCanvases(daoId).length, 0);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoPriceFactor(daoId), 20_000);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoFeePoolETHRatio(daoId), 3000);
        assertEq(ID4AProtocolReadable(address(protocol)).getDaoFeePoolETHRatioFlatPrice(daoId), 3500);
    }
}

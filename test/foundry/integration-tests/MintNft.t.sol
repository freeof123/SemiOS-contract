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

contract MintNftTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_mintNFT_pay_lower_price_when_canvasRebateRatioInBps_is_set() public {
        hoax(daoCreator.addr);
        daoId = daoProxy.createProject{ value: 0.1 ether }(
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
                isProgressiveJackpot: false
            }),
            0
        );
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
        hoax(daoCreator.addr);
        daoId = daoProxy.createProject{ value: 0.1 ether }(
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
                isProgressiveJackpot: false
            }),
            0
        );
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
}

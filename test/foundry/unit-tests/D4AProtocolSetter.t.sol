// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import { D4AProtocolReadable } from "contracts/D4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";

contract D4AProtocolSetterTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_setDaoParams_when_daoFloorPrice_is_zero() public {
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 30,
                floorPriceRank: 9999,
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
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 12_600,
                isProgressiveJackpot: true
            }),
            0
        );
        drb.changeRound(1);

        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoParams(
            daoId, 0, 1, 9999, PriceTemplateType(0), 20_000, 300, 9500, 0, 250, 750
        );
    }

    /**
     * dev when current price is lower than new floor price, should increase current round price to new floor price
     * instead of floor price / 2
     */
    function test_setDaoFloorPrice_when_current_price_is_lower_than_new_price() public {
        // set DAO floor price to 0.5 ETH, change round such that current price is 0.25 ETH, change price to 0.3 ETH
        // canvas price now should be 0.3 ETH
        hoax(daoCreator.addr);
        bytes32 daoId = daoProxy.createProject{ value: 0.1 ether }(
            DaoMetadataParam({
                startDrb: 1,
                mintableRounds: 30,
                floorPriceRank: 7,
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
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 12_600,
                isProgressiveJackpot: true
            }),
            0
        );
        drb.changeRound(1);

        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 0);

        drb.changeRound(5);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.25 ether);
        hoax(daoCreator.addr);
        D4AProtocolSetter(address(protocol)).setDaoFloorPrice(daoId, 0.3 ether);
        assertEq(D4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId), 0.3 ether);
    }
}

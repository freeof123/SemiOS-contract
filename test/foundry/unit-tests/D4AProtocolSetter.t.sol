// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
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
}

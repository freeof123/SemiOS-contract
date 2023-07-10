// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";

contract GetRoundRewardTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_1_decayLife_notProgressiveJackpot()
        public
    {
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
                rewardTemplateType: RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE,
                rewardDecayFactor: 20_000,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            0
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
            500_000_000_465_661_287_741_420_127,
            "round 1"
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
            500_000_000_465_661_287_741_420_127,
            "round 2"
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 500_000_000_465_661_287_741_420_127
        );

        drb.changeRound(2);
        hoax(canvasCreator.addr);
        bytes32 canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);

        string memory tokenUri = "test token uri 1";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        startHoax(nftMinter.addr);
        protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        vm.stopPrank();

        drb.changeRound(3);
        assertEq(
            ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
            500_000_000_465_661_287_741_420_127,
            "round 2"
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
            250_000_000_232_830_643_870_710_063,
            "round 3"
        );
        assertEq(
            ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 4),
            250_000_000_232_830_643_870_710_063,
            "round 4"
        );
    }
}

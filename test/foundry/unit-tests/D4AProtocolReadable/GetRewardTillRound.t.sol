// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";

contract GetRewardTillRoundTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    function test_getRewardTillRound_Exponential_reward_issuance_1dot26x_decayFactor_ProgressiveJackpot_30_mintableRounds(
    )
        public
    {
        // _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 12_600, true);

        // assertEq(ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 1), 0);
        // assertEq(ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 2), 0);

        // {
        //     drb.changeRound(2);
        //     string memory tokenUri = "test token uri 1";
        //     uint256 flatPrice = 0;
        //     bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        //     startHoax(nftMinter.addr);
        //     protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
        //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        //     );
        //     vm.stopPrank();
        // }

        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 3), 370_479_534_683_558_798_115_818_789
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 23),
        // 370_479_534_683_558_798_115_818_789
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 30),
        // 370_479_534_683_558_798_115_818_789
        // );

        // {
        //     drb.changeRound(23);
        //     string memory tokenUri = "test token uri 2";
        //     uint256 flatPrice = 0;
        //     bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        //     startHoax(nftMinter.addr);
        //     protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
        //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        //     );
        //     vm.stopPrank();
        // }

        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 3), 370_479_534_683_558_798_115_818_789
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 23),
        // 996_056_405_767_309_103_476_334_563
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 30),
        // 996_056_405_767_309_103_476_334_563
        // );
    }

    function test_getRewardTillRound_Exponential_reward_issuance_1dot0261x_decayFactor_ProgressiveJackpot_270_mintableRounds(
    )
        public
    {
        // _createDaoAndCanvas(270, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 10_261, true);

        // {
        //     string memory tokenUri = "test token uri 1";
        //     uint256 flatPrice = 0;
        //     bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        //     startHoax(nftMinter.addr);
        //     protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
        //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        //     );
        //     vm.stopPrank();
        // }

        // drb.changeRound(3);
        // hoax(daoCreator.addr);
        // D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 271);

        // drb.changeRound(4);
        // {
        //     string memory tokenUri = "test token uri 2";
        //     uint256 flatPrice = 0;
        //     bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
        //     startHoax(nftMinter.addr);
        //     protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
        //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        //     );
        //     vm.stopPrank();
        // }

        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 1), 25_460_363_831_576_134_072_973_665
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 2), 25_460_363_831_576_134_072_973_665
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 3), 25_460_363_831_576_134_072_973_665
        // );
        // assertEq(
        //     ID4AProtocolReadable(address(protocol)).getRewardTillRound(daoId, 4), 98_020_633_177_309_110_468_408_999
        // );
    }

    function _createDaoAndCanvas(
        uint256 mintableRound,
        RewardTemplateType rewardTemplateType,
        uint256 rewardDecayFactor,
        bool isProgressiveJackpot
    )
        internal
    {
        // DeployHelper.CreateDaoParam memory createDaoParam;
        // createDaoParam.mintableRound = mintableRound;
        // createDaoParam.rewardTemplateType = rewardTemplateType;
        // createDaoParam.rewardDecayFactor = rewardDecayFactor;
        // createDaoParam.isProgressiveJackpot = isProgressiveJackpot;
        // daoId = _createDao(createDaoParam);

        // drb.changeRound(1);
        // hoax(canvasCreator.addr);
        // canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);
    }
}

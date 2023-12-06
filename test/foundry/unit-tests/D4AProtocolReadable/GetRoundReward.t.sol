// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { FixedPointMathLib as Math } from "solmate/utils/FixedPointMathLib.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { D4AProtocolSetter } from "contracts/D4AProtocolSetter.sol";
import { D4AERC20 } from "contracts/D4AERC20.sol";

contract GetRoundRewardTest is DeployHelper {
    MintNftSigUtils public sigUtils;

    bytes32 public daoId;
    bytes32 public canvasId;

    function setUp() public {
        setUpEnv();
        sigUtils = new MintNftSigUtils(address(protocol));
    }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_notProgressiveJackpot_max_mintableRounds()
    //         public
    //     {
    //         // _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 20_000, false);

    //         // for (uint256 i = 1; i < 11; i++) {
    //         //     assertApproxEqAbs(
    //         //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //         //         5e26,
    //         //         1,
    //         //         string.concat("round ", vm.toString(i))
    //         //     );
    //         // }

    //         // // mint for 30 rounds
    //         // for (uint256 j = 2; j < 368; j++) {
    //         //     drb.changeRound(j);

    //         //     string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //         //     uint256 flatPrice = 0;
    //         //     bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         //     startHoax(nftMinter.addr);
    //         //     protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //         //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         //     );
    //         //     vm.stopPrank();

    //         //     uint256 temp = 5e26;
    //         //     for (uint256 k; k < j - 2; k++) {
    //         //         temp /= 2;
    //         //     }
    //         //     assertApproxEqAbs(
    //         //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //         //         temp,
    //         //         1,
    //         //         string.concat("round ", vm.toString(j))
    //         //     );

    //         //     drb.changeRound(j + 1);

    //         //     assertApproxEqAbs(
    //         //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //         //         temp,
    //         //         1,
    //         //         string.concat("round ", vm.toString(j))
    //         //     );
    //         //     for (uint256 i = j + 1; i < j + 11; i++) {
    //         //         assertApproxEqAbs(
    //         //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //         //             temp / 2,
    //         //             1,
    //         //             string.concat("round ", vm.toString(i))
    //         //         );
    //         //     }
    //         // }

    //         // drb.changeRound(371);
    //         // // 有claim但是这个测试过了
    //         // protocol.claimProjectERC20Reward(daoId);
    //         // assertApproxEqAbs(
    //         //     D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //         //     ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
    //         //     100,
    //         //     "total supply"
    //         // );
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_3x_decayFactor_notProgressiveJackpot_max_mintableRounds()
    //         public
    //     {
    //         // _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 30_000, false);

    //         // for (uint256 i = 1; i < 11; i++) {
    //         //     assertEq(
    //         //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //         //         666_666_666_666_666_666_666_666_667,
    //         //         string.concat("round ", vm.toString(i))
    //         //     );
    //         // }

    //         // // mint for 30 rounds
    //         // for (uint256 j = 2; j < 368; j++) {
    //         //     drb.changeRound(j);

    //         //     string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //         //     uint256 flatPrice = 0;
    //         //     bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //         //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //         //     startHoax(nftMinter.addr);
    //         //     protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //         //         daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //         //     );
    //         //     vm.stopPrank();

    //         //     uint256 temp = 666_666_666_666_666_666_666_666_667;
    //         //     // for (uint256 k; k < j - 2; k++) {
    //         //     //     temp /= 3;
    //         //     // }
    //         //     assertApproxEqAbs(
    //         //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //         //         temp * Math.rpow(uint256(1e27) / 3, j - 2, 1e27) / 1e27,
    //         //         1,
    //         //         string.concat("round ", vm.toString(j))
    //         //     );

    //         //     drb.changeRound(j + 1);

    //         //     assertApproxEqAbs(
    //         //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //         //         temp * Math.rpow(uint256(1e27) / 3, j - 2, 1e27) / 1e27,
    //         //         1,
    //         //         string.concat("round ", vm.toString(j))
    //         //     );
    //         //     for (uint256 i = j + 1; i < j + 11; i++) {
    //         //         assertApproxEqAbs(
    //         //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //         //             temp * Math.rpow(uint256(1e27) / 3, j - 2, 1e27) / 1e27 / 3,
    //         //             1,
    //         //             string.concat("round ", vm.toString(i))
    //         //         );
    //         //     }
    //         // }

    //         // drb.changeRound(371);
    //         // protocol.claimProjectERC20Reward(daoId);
    //         // assertApproxEqAbs(
    //         //     D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //         //     ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
    //         //     100,
    //         //     "total supply"
    //         // );
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_notProgressiveJackpot_max_mintableRounds(
    //     )
    //         public
    //     {
    //         _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 15_000, false);

    //         for (uint256 i = 1; i < 11; i++) {
    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //                 333_333_333_333_333_333_333_333_334,
    //                 string.concat("round ", vm.toString(i))
    //             );
    //         }

    //         // mint for 30 rounds
    //         for (uint256 j = 2; j < 368; j++) {
    //             drb.changeRound(j);

    //             string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();

    //             uint256 temp = 333_333_333_333_333_333_333_333_334;
    //             // for (uint256 k; k < j - 2; k++) {
    //             //     temp /= 3;
    //             // }
    //             assertApproxEqAbs(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
    //                 1,
    //                 string.concat("round ", vm.toString(j))
    //             );

    //             drb.changeRound(j + 1);

    //             assertApproxEqAbs(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
    //                 1,
    //                 string.concat("round ", vm.toString(j))
    //             );
    //             for (uint256 i = j + 1; i < j + 11; i++) {
    //                 uint256 roundReward =
    //                     temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27 * 10_000 / 15_000;
    //                 assertApproxEqAbs(
    //                     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //                     roundReward,
    //                     1,
    //                     string.concat("round ", vm.toString(i))
    //                 );
    //             }
    //         }

    //         drb.changeRound(371);
    //         protocol.claimProjectERC20Reward(daoId);
    //         assertApproxEqAbs(
    //             D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //             ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
    //             100,
    //             "total supply"
    //         );
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_notProgressiveJackpot_30_mintableRounds(
    //     )
    //         public
    //     {
    //         vm.skip(true);
    //         _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 15_000, false);

    //         for (uint256 i = 1; i < 11; i++) {
    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //                 333_335_071_707_416_068_263_145_206,
    //                 string.concat("round ", vm.toString(i))
    //             );
    //         }

    //         // mint for 30 rounds
    //         for (uint256 j = 2; j < 32; j++) {
    //             drb.changeRound(j);

    //             string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();

    //             uint256 temp = 333_335_071_707_416_068_263_145_206;
    //             // for (uint256 k; k < j - 2; k++) {
    //             //     temp /= 3;
    //             // }
    //             assertApproxEqAbs(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
    //                 1,
    //                 string.concat("round ", vm.toString(j))
    //             );

    //             drb.changeRound(j + 1);

    //             assertApproxEqAbs(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27,
    //                 1,
    //                 string.concat("round ", vm.toString(j))
    //             );
    //             for (uint256 i = j + 1; i < j + 11 && i < 31; i++) {
    //                 uint256 roundReward =
    //                     temp * Math.rpow(uint256(1e27) * 10_000 / 15_000, j - 2, 1e27) / 1e27 * 10_000 / 15_000;
    //                 assertApproxEqAbs(
    //                     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //                     roundReward,
    //                     1,
    //                     string.concat("round ", vm.toString(i))
    //                 );
    //             }
    //         }

    //         drb.changeRound(42);
    //         // claim问题
    //         protocol.claimProjectERC20Reward(daoId);
    //         assertApproxEqAbs(
    //             D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //             ID4AProtocolReadable(address(protocol)).getDaoTokenMaxSupply(daoId),
    //             100,
    //             "total supply"
    //         );
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 20_000, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 500_000_000_465_661_287_741_420_127);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 750_000_000_698_491_931_612_130_190);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 875_000_000_814_907_253_547_485_222);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_996_186_234_053_397_769_158_144);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_999);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_2x_decayFactor_ProgressiveJackpot_max_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 20_000, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1), 5e26);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 75e25);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3), 875e24);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_996_185_302_734_375_000_000_000);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_068_677_425_384_521_484);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 1e27);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_2dot65x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 26_500, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 622_641_509_434_087_250_289_909_344);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 857_600_569_597_893_759_833_271_359);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 946_264_365_886_122_631_359_068_346);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_999_975_924_758_731_203_841_883);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_999);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_2dot65x_decayFactor_ProgressiveJackpot_max_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 26_500, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 622_641_509_433_962_264_150_943_397);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 857_600_569_597_721_609_113_563_546);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 946_264_365_885_932_682_684_363_602);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_999_975_924_557_995_894_577_851);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_799_264_685_903_216);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 1e27);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 15_000, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 333_335_071_707_416_068_263_145_206);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 555_558_452_845_693_447_105_242_009);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 703_707_373_604_545_032_999_973_211);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_328_572_108_891_710_282_000_512);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_998);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_1dot5x_decayFactor_ProgressiveJackpot_max_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(366, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 15_000, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 333_333_333_333_333_333_333_333_334);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 555_555_555_555_555_555_555_555_556);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 703_703_703_703_703_703_703_703_704);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18),
    // 999_323_360_515_401_135_637_924_405);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_994_784_904_949_153_436_736_982);
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100),
    // 999_999_999_999_999_997_540_345_573
    //         );
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300), 1e27);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366), 1e27);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    //     }

    //     function test_getRoundReward_Linear_reward_issuance_ProgressiveJackpot_30_mintableRounds() public {
    //         _createDaoAndCanvas(30, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 33_333_333_333_333_333_333_333_333);
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 33_333_333_333_333_333_333_333_333
    // * 2
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3), 33_333_333_333_333_333_333_333_333
    // * 3
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18), 33_333_333_333_333_333_333_333_333
    // * 18
    //         );
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 999_999_999_999_999_999_999_999_990);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    //     }

    //     function test_getRoundReward_Linear_reward_issuance_ProgressiveJackpot_max_mintableRounds() public {
    //         _createDaoAndCanvas(366, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 2_732_240_437_158_469_945_355_191);
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 2_732_240_437_158_469_945_355_191 *
    // 2
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3), 2_732_240_437_158_469_945_355_191 *
    // 3
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 18), 2_732_240_437_158_469_945_355_191
    // * 18
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30), 2_732_240_437_158_469_945_355_191
    // * 30
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 100),
    // 273_224_043_715_846_994_535_519_100
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 200),
    // 273_224_043_715_846_994_535_519_100 * 2
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 300),
    // 273_224_043_715_846_994_535_519_100 * 3
    //         );
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 366),
    // 999_999_999_999_999_999_999_999_906
    //         );
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 367);
    //     }

    //     function test_getRoundReward_Linear_reward_issuance_notProgressiveJackpot_30_mintableRounds() public {
    //         vm.skip(true);
    //         _createDaoAndCanvas(30, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, false);

    //         for (uint256 i = 1; i < 11; i++) {
    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //                 33_333_333_333_333_333_333_333_333,
    //                 string.concat("round ", vm.toString(i))
    //             );
    //         }

    //         // mint for 30 rounds
    //         for (uint256 j = 2; j < 32; j++) {
    //             drb.changeRound(j);

    //             string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();

    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 33_333_333_333_333_333_333_333_333,
    //                 string.concat("round ", vm.toString(j))
    //             );

    //             drb.changeRound(j + 1);

    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 33_333_333_333_333_333_333_333_333,
    //                 string.concat("round ", vm.toString(j))
    //             );
    //             for (uint256 i = j + 1; i < j + 11 && i < 31; i++) {
    //                 assertEq(
    //                     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                     33_333_333_333_333_333_333_333_333,
    //                     string.concat("round ", vm.toString(j))
    //                 );
    //             }
    //         }

    //         drb.changeRound(42);
    //         // claim问题
    //         protocol.claimProjectERC20Reward(daoId);
    //         assertEq(
    //             D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //             999_999_999_999_999_999_999_999_990,
    //             "total supply"
    //         );
    //     }

    //     function test_getRoundReward_Linear_reward_issuance_notProgressiveJackpot_max_mintableRounds() public {
    //         vm.skip(true);
    //         _createDaoAndCanvas(366, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, false);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 2_732_240_437_158_469_945_355_191);
    //         for (uint256 i = 1; i < 11; i++) {
    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, i),
    //                 2_732_240_437_158_469_945_355_191,
    //                 string.concat("round ", vm.toString(i))
    //             );
    //         }

    //         // mint for 366 rounds
    //         for (uint256 j = 2; j < 368; j++) {
    //             drb.changeRound(j);

    //             string memory tokenUri = string.concat("test token uri", vm.toString(j));
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();

    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 2_732_240_437_158_469_945_355_191,
    //                 string.concat("round ", vm.toString(j))
    //             );

    //             drb.changeRound(j + 1);

    //             assertEq(
    //                 ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                 2_732_240_437_158_469_945_355_191,
    //                 string.concat("round ", vm.toString(j))
    //             );
    //             for (uint256 i = j + 1; i < j + 11 && i < 367; i++) {
    //                 assertEq(
    //                     ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, j),
    //                     2_732_240_437_158_469_945_355_191,
    //                     string.concat("round ", vm.toString(j))
    //                 );
    //             }
    //         }

    //         drb.changeRound(420);
    //         // claim问题
    //         protocol.claimProjectERC20Reward(daoId);
    //         assertEq(
    //             D4AERC20(ID4AProtocolReadable(address(protocol)).getDaoToken(daoId)).totalSupply(),
    //             999_999_999_999_999_999_999_999_906,
    //             "total supply"
    //         );
    //     }

    //     function
    // test_getRoundReward_Exponential_reward_issuance_1dot26x_decayFactor_ProgressiveJackpot_30_mintableRounds()
    //         public
    //     {
    //         _createDaoAndCanvas(30, RewardTemplateType.EXPONENTIAL_REWARD_ISSUANCE, 12_600, true);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 206_550_537_035_966_409_568_996_316);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 370_479_534_683_558_798_115_818_789);

    //         {
    //             drb.changeRound(2);
    //             string memory tokenUri = "test token uri 1";
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();
    //         }

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 130_102_379_085_390_784_560_970_216);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 23),
    // 625_576_871_083_750_305_360_515_774);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 30),
    // 629_520_465_316_441_201_884_181_206);
    //         vm.expectRevert(ExceedMaxMintableRound.selector);
    //         ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 31);
    //     }

    //     function test_getRoundReward_on_new_checkpoint() public {
    //         _createDaoAndCanvas(90, RewardTemplateType.LINEAR_REWARD_ISSUANCE, 0, true);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 11_111_111_111_111_111_111_111_111);
    //         assertEq(
    //             ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2), 11_111_111_111_111_111_111_111_111
    // * 2
    //         );

    //         {
    //             string memory tokenUri = "test token uri 1";
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();
    //         }

    //         {
    //             drb.changeRound(2);
    //             string memory tokenUri = "test token uri 2";
    //             uint256 flatPrice = 0;
    //             bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
    //             (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreator.key, digest);
    //             startHoax(nftMinter.addr);
    //             protocol.mintNFT{ value: ID4AProtocolReadable(address(protocol)).getCanvasNextPrice(canvasId) }(
    //                 daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
    //             );
    //             vm.stopPrank();
    //         }

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 11_111_111_111_111_111_111_111_111);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 11_111_111_111_111_111_111_111_111);

    //         hoax(daoCreator.addr);
    //         D4AProtocolSetter(address(protocol)).setDaoMintableRound(daoId, 120);

    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 1),
    // 11_111_111_111_111_111_111_111_111);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 2),
    // 11_111_111_111_111_111_111_111_111);
    //         assertEq(ID4AProtocolReadable(address(protocol)).getRoundReward(daoId, 3),
    // 8_286_252_354_048_964_218_455_743);
    //     }

    //     function _createDaoAndCanvas(
    //         uint256 mintableRound,
    //         RewardTemplateType rewardTemplateType,
    //         uint256 rewardDecayFactor,
    //         bool isProgressiveJackpot
    //     )
    //         internal
    //     {
    //         DeployHelper.CreateDaoParam memory createDaoParam;
    //         createDaoParam.mintableRound = mintableRound;
    //         createDaoParam.rewardTemplateType = rewardTemplateType;
    //         createDaoParam.rewardDecayFactor = rewardDecayFactor;
    //         createDaoParam.isProgressiveJackpot = isProgressiveJackpot;
    //         daoId = _createDao(createDaoParam);

    //         drb.changeRound(1);
    //         hoax(canvasCreator.addr);
    //         canvasId = protocol.createCanvas{ value: 0.01 ether }(daoId, "test canvas uri", new bytes32[](0), 3000);
    //     }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, AllRatioParam } from "contracts/interface/D4AStructs.sol";
import { ClaimMultiRewardParam } from "contracts/D4AUniversalClaimer.sol";

import { ExceedMinterMaxMintAmount, NotAncestorDao } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

import { console2 } from "forge-std/Test.sol";
import { LibString } from "solady/utils/LibString.sol";

import "contracts/interface/D4AStructs.sol";

contract ProtoDaoEventTest is DeployHelper {
    using LibString for string;

    event ChildrenSet(
        bytes32 daoId,
        bytes32[] childrenDaoId,
        uint256[] erc20Ratios,
        uint256[] ethRatios,
        uint256 redeemPoolRatioETH,
        uint256 selfRewardRatioERC20,
        uint256 selfRewardRatioETH
    );

    event RatioSet(bytes32 daoId, AllRatioParam vars);

    function _getDaoId(DeployHelper.CreateDaoParam memory createDaoParam) internal view returns (bytes32) {
        CreateContinuousDaoParam memory vars;
        DaoMintCapParam memory daoMintCapParam;

        vars.existDaoId = bytes32(0);
        vars.daoMetadataParam = DaoMetadataParam({
            startBlock: 0,
            mintableRounds: createDaoParam.mintableRound == 0 ? 60 : createDaoParam.mintableRound,
            duration: createDaoParam.duration == 0 ? 1e18 : createDaoParam.duration,
            floorPrice: (createDaoParam.floorPrice == 0 ? 0.01 ether : createDaoParam.floorPrice),
            maxNftRank: 2,
            royaltyFee: createDaoParam.royaltyFee == 0 ? 1000 : createDaoParam.royaltyFee,
            projectUri: bytes(createDaoParam.daoUri).length == 0 ? "test dao uri" : createDaoParam.daoUri,
            projectIndex: 0
        });
        vars.whitelist = Whitelist({
            minterMerkleRoot: bytes32(0),
            minterNFTHolderPasses: createDaoParam.minterNFTHolderPasses,
            minterNFTIdHolderPasses: createDaoParam.minterNFTIdHolderPasses,
            canvasCreatorMerkleRoot: createDaoParam.canvasCreatorMerkleRoot,
            canvasCreatorNFTHolderPasses: createDaoParam.canvasCreatorNFTHolderPasses,
            canvasCreatorNFTIdHolderPasses: createDaoParam.canvasCreatorNFTIdHolderPasses
        });
        vars.blacklist = Blacklist({
            minterAccounts: createDaoParam.minterAccounts,
            canvasCreatorAccounts: createDaoParam.canvasCreatorAccounts
        });

        vars.templateParam = TemplateParam({
            priceTemplateType: createDaoParam.priceTemplateType, //0 for EXPONENTIAL_PRICE_VARIATION,
            priceFactor: createDaoParam.priceFactor == 0 ? 20_000 : createDaoParam.priceFactor,
            rewardTemplateType: RewardTemplateType.UNIFORM_DISTRIBUTION_REWARD,
            rewardDecayFactor: 0,
            isProgressiveJackpot: createDaoParam.isProgressiveJackpot
        });
        vars.basicDaoParam = BasicDaoParam({
            canvasId: createDaoParam.canvasId,
            canvasUri: "test dao creator canvas uri",
            daoName: "test dao"
        });
        vars.continuousDaoParam = ContinuousDaoParam({
            reserveNftNumber: createDaoParam.reserveNftNumber == 0 ? 1000 : createDaoParam.reserveNftNumber, // 传一个500进来，spetialTokenUri应该501会Revert
            unifiedPriceModeOff: createDaoParam.uniPriceModeOff, // 把这个模式关掉之后应该会和之前按照签名的方式一样铸造，即铸造价格为0.01
            unifiedPrice: createDaoParam.unifiedPrice == 0 ? 0.01 ether : createDaoParam.unifiedPrice,
            needMintableWork: createDaoParam.needMintableWork,
            dailyMintCap: createDaoParam.dailyMintCap == 0 ? 100 : createDaoParam.dailyMintCap,
            childrenDaoId: createDaoParam.childrenDaoId,
            childrenDaoRatiosERC20: createDaoParam.childrenDaoRatiosERC20,
            childrenDaoRatiosETH: createDaoParam.childrenDaoRatiosETH,
            redeemPoolRatioETH: createDaoParam.redeemPoolRatioETH,
            selfRewardRatioERC20: createDaoParam.selfRewardRatioERC20,
            selfRewardRatioETH: createDaoParam.selfRewardRatioETH,
            isAncestorDao: createDaoParam.isBasicDao ? true : false,
            daoToken: createDaoParam.thirdPartyToken,
            topUpMode: createDaoParam.topUpMode,
            infiniteMode: createDaoParam.infiniteMode,
            erc20PaymentMode: createDaoParam.erc20PaymentMode,
            ownershipUri: createDaoParam.ownershipUri.eq("") ? "test ownership uri" : createDaoParam.ownershipUri,
            inputToken: createDaoParam.inputToken
        });
        if (!createDaoParam.noDefaultRatio) {
            vars.allRatioParam = AllRatioParam({
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatio: 750,
                assetPoolMintFeeRatio: 2000,
                redeemPoolMintFeeRatio: 7000,
                // * 1.3 add
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatioFiatPrice: 250,
                assetPoolMintFeeRatioFiatPrice: 3500,
                redeemPoolMintFeeRatioFiatPrice: 6000,
                // l.protocolERC20RatioInBps = 200
                // sum = 9800
                minterERC20RewardRatio: 800,
                canvasCreatorERC20RewardRatio: 2000,
                daoCreatorERC20RewardRatio: 7000,
                // sum = 9800
                minterETHRewardRatio: 800,
                canvasCreatorETHRewardRatio: 2000,
                daoCreatorETHRewardRatio: 7000
            });
        } else {
            vars.allRatioParam = AllRatioParam({
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatio: createDaoParam.canvasCreatorMintFeeRatio,
                assetPoolMintFeeRatio: createDaoParam.assetPoolMintFeeRatio,
                redeemPoolMintFeeRatio: createDaoParam.redeemPoolMintFeeRatio,
                // * 1.3 add
                // l.protocolMintFeeRatioInBps = 250
                // sum = 9750
                canvasCreatorMintFeeRatioFiatPrice: createDaoParam.canvasCreatorMintFeeRatioFiatPrice,
                assetPoolMintFeeRatioFiatPrice: createDaoParam.assetPoolMintFeeRatioFiatPrice,
                redeemPoolMintFeeRatioFiatPrice: createDaoParam.redeemPoolMintFeeRatioFiatPrice,
                // l.protocolERC20RatioInBps = 200
                // sum = 9800
                minterERC20RewardRatio: createDaoParam.minterERC20RewardRatio,
                canvasCreatorERC20RewardRatio: createDaoParam.canvasCreatorERC20RewardRatio,
                daoCreatorERC20RewardRatio: createDaoParam.daoCreatorERC20RewardRatio,
                // sum = 9800
                minterETHRewardRatio: createDaoParam.minterETHRewardRatio,
                canvasCreatorETHRewardRatio: createDaoParam.canvasCreatorETHRewardRatio,
                daoCreatorETHRewardRatio: createDaoParam.daoCreatorETHRewardRatio
            });
        }

        bytes memory datas = abi.encodeCall(
            PDCreate.createDao,
            (
                CreateSemiDaoParam(
                    vars.existDaoId,
                    vars.daoMetadataParam,
                    vars.whitelist,
                    vars.blacklist,
                    daoMintCapParam,
                    vars.nftMinterCapInfo,
                    vars.nftMinterCapIdInfo,
                    vars.templateParam,
                    vars.basicDaoParam,
                    vars.continuousDaoParam,
                    vars.allRatioParam,
                    20
                )
            )
        );
        return keccak256(abi.encodePacked(block.number, daoCreator.addr, datas, msg.sender));
    }

    function setUp() public {
        super.setUpEnv();
    }

    // testcase 1.3-15
    function test_pdcreate_topup_ratio_event() public {
        // dao: daoCreator
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.existDaoId = bytes32(0);
        param.isBasicDao = true;
        param.selfRewardRatioETH = 10_000;
        param.selfRewardRatioERC20 = 10_000;
        param.noPermission = true;
        param.topUpMode = true;
        bytes32 _daoId = _getDaoId(param);

        //vm.expectEmit(false, false, false, true);
        vm.expectEmit(address(protocol));
        emit ChildrenSet(_daoId, new bytes32[](0), new uint256[](0), new uint256[](0), 0, 10_000, 0);
        emit RatioSet(_daoId, AllRatioParam(0, 0, 0, 0, 0, 0, 10_000, 0, 0, 0, 0, 0));

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        assertEq(daoId, _daoId);
    }
}

/*
vars.allRatioForFundingParam = AllRatioForFundingParam({
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = true
            canvasCreatorMintFeeRatio: 750,
            assetPoolMintFeeRatio: 2000,
            redeemPoolMintFeeRatio: 7000,


            // * 1.3 add
            // l.protocolMintFeeRatioInBps = 250
            // sum = 9750
            // !!! enable when param.uniPriceModeOff = false, default is false
            canvasCreatorMintFeeRatioFiatPrice: 250,
            assetPoolMintFeeRatioFiatPrice: 3500,
            redeemPoolMintFeeRatioFiatPrice: 6000,


            // l.protocolERC20RatioInBps = 200
            // sum = 9800
            // !!! ratio for param.selfRewardRatioERC20
            minterERC20RewardRatio: 800,
            canvasCreatorERC20RewardRatio: 2000,
            daoCreatorERC20RewardRatio: 7000,


            // sum = 9800
            // !!! ratio for param.selfRewardRatioETH
            minterETHRewardRatio: 800,
            canvasCreatorETHRewardRatio: 2000,
            daoCreatorETHRewardRatio: 7000
        });
*/

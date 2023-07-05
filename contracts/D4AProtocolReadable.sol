// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { SettingsStorage } from "./storages/SettingsStorage.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { IPriceTemplate } from "contracts/interface/IPriceTemplate.sol";
import { IRewardTemplate } from "contracts/interface/IRewardTemplate.sol";

contract D4AProtocolReadable is ID4AProtocolReadable {
    // legacy functions
    function getProjectCanvasAt(bytes32 _project_id, uint256 _index) public view returns (bytes32) {
        return DaoStorage.layout().daoInfos[_project_id].canvases[_index];
    }

    function getProjectInfo(bytes32 _project_id)
        public
        view
        returns (
            uint256 start_prb,
            uint256 mintable_rounds,
            uint256 max_nft_amount,
            address fee_pool,
            uint96 royalty_fee,
            uint256 index,
            string memory uri,
            uint256 erc20_total_supply
        )
    {
        DaoStorage.DaoInfo storage pi = DaoStorage.layout().daoInfos[_project_id];
        start_prb = pi.startRound;
        mintable_rounds = pi.mintableRound;
        max_nft_amount = pi.nftMaxSupply;
        fee_pool = pi.daoFeePool;
        royalty_fee = pi.royaltyFeeInBps;
        index = pi.daoIndex;
        uri = pi.daoUri;
        erc20_total_supply = pi.tokenMaxSupply;
    }

    function getProjectFloorPrice(bytes32 _project_id) public view returns (uint256) {
        return PriceStorage.layout().daoFloorPrices[_project_id];
    }

    function getProjectTokens(bytes32 _project_id) public view returns (address erc20_token, address erc721_token) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[_project_id];
        erc20_token = daoInfo.token;
        erc721_token = daoInfo.nft;
    }

    function getCanvasNFTCount(bytes32 _canvas_id) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].tokenIds.length;
    }

    function getTokenIDAt(bytes32 _canvas_id, uint256 _index) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].tokenIds[_index];
    }

    function getCanvasProject(bytes32 _canvas_id) public view returns (bytes32) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].daoId;
    }

    function getCanvasURI(bytes32 _canvas_id) public view returns (string memory) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].canvasUri;
    }

    function getProjectCanvasCount(bytes32 daoId) public view returns (uint256) {
        return DaoStorage.layout().daoInfos[daoId].canvases.length;
    }

    // new functions
    // DAO related functions
    function getDaoStartRound(bytes32 daoId) external view returns (uint256 startRound) {
        return DaoStorage.layout().daoInfos[daoId].startRound;
    }

    function getDaoMintableRound(bytes32 daoId) external view returns (uint256 mintableRound) {
        return DaoStorage.layout().daoInfos[daoId].mintableRound;
    }

    function getDaoIndex(bytes32 daoId) external view returns (uint256 index) {
        return DaoStorage.layout().daoInfos[daoId].daoIndex;
    }

    function getDaoUri(bytes32 daoId) external view returns (string memory daoUri) {
        return DaoStorage.layout().daoInfos[daoId].daoUri;
    }

    function getDaoFeePool(bytes32 daoId) external view returns (address daoFeePool) {
        return DaoStorage.layout().daoInfos[daoId].daoFeePool;
    }

    function getDaoToken(bytes32 daoId) external view returns (address token) {
        return DaoStorage.layout().daoInfos[daoId].token;
    }

    function getDaoTokenMaxSupply(bytes32 daoId) external view returns (uint256 tokenMaxSupply) {
        return DaoStorage.layout().daoInfos[daoId].tokenMaxSupply;
    }

    function getDaoNft(bytes32 daoId) external view returns (address nft) {
        return DaoStorage.layout().daoInfos[daoId].nft;
    }

    function getDaoNftMaxSupply(bytes32 daoId) external view returns (uint256 nftMaxSupply) {
        return DaoStorage.layout().daoInfos[daoId].nftMaxSupply;
    }

    function getDaoNftTotalSupply(bytes32 daoId) external view returns (uint256 nftTotalSupply) {
        return DaoStorage.layout().daoInfos[daoId].nftTotalSupply;
    }

    function getDaoNftRoyaltyFeeInBps(bytes32 daoId) external view returns (uint96 royaltyFeeInBps) {
        return DaoStorage.layout().daoInfos[daoId].royaltyFeeInBps;
    }

    function getDaoCanvases(bytes32 daoId) external view returns (bytes32[] memory canvases) {
        return DaoStorage.layout().daoInfos[daoId].canvases;
    }

    function getDaoPriceTemplate(bytes32 daoId) external view returns (address priceTemplate) {
        return SettingsStorage.layout().priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)];
    }

    function getDaoPriceFactor(bytes32 daoId) external view returns (uint256 priceFactor) {
        return DaoStorage.layout().daoInfos[daoId].nftPriceFactor;
    }

    function getDaoRewardTemplate(bytes32 daoId) external view override returns (address rewardTemplate) {
        return SettingsStorage.layout().rewardTemplates[uint8(DaoStorage.layout().daoInfos[daoId].rewardTemplateType)];
    }

    function getDaoMintCap(bytes32 daoId) public view returns (uint32) {
        return DaoStorage.layout().daoInfos[daoId].daoMintInfo.daoMintCap;
    }

    function getUserMintInfo(bytes32 daoId, address account) public view returns (uint32 minted, uint32 userMintCap) {
        minted = DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[account].minted;
        userMintCap = DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[account].mintCap;
    }

    function getDaoFeePoolETHRatio(bytes32 daoId) public view returns (uint256) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.daoFeePoolETHRatioInBps == 0) {
            return SettingsStorage.layout().daoFeePoolMintFeeRatioInBps;
        }
        return daoInfo.daoFeePoolETHRatioInBps;
    }

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) public view returns (uint256) {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.daoFeePoolETHRatioInBpsFlatPrice == 0) {
            return SettingsStorage.layout().daoFeePoolMintFeeRatioInBpsFlatPrice;
        }
        return daoInfo.daoFeePoolETHRatioInBpsFlatPrice;
    }

    // canvas related functions
    function getCanvasDaoId(bytes32 canvasId) external view returns (bytes32 daoId) {
        return CanvasStorage.layout().canvasInfos[canvasId].daoId;
    }

    function getCanvasTokenIds(bytes32 canvasId) external view returns (uint256[] memory tokenIds) {
        return CanvasStorage.layout().canvasInfos[canvasId].tokenIds;
    }

    function getCanvasIndex(bytes32 _canvas_id) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].index;
    }

    function getCanvasUri(bytes32 canvasId) external view returns (string memory canvasUri) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasUri;
    }

    function getCanvasRebateRatioInBps(bytes32 canvasId) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasRebateRatioInBps;
    }

    // prices related functions
    function getCanvasLastPrice(bytes32 canvasId) public view returns (uint256 round, uint256 price) {
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        return (mintInfo.round, mintInfo.price);
    }

    function getCanvasNextPrice(bytes32 canvasId) public view returns (uint256) {
        bytes32 daoId = CanvasStorage.layout().canvasInfos[canvasId].daoId;
        uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        DaoStorage.DaoInfo storage pi = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        return IPriceTemplate(
            settingsStorage.priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)]
        ).getCanvasNextPrice(
            pi.startRound, settingsStorage.drb.currentRound(), pi.nftPriceFactor, daoFloorPrice, maxPrice, mintInfo
        );
    }

    function getDaoMaxPriceInfo(bytes32 daoId) external view returns (uint256 round, uint256 price) {
        PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
        return (maxPrice.round, maxPrice.price);
    }

    function getDaoFloorPrice(bytes32 daoId) external view returns (uint256 floorPrice) {
        return PriceStorage.layout().daoFloorPrices[daoId];
    }

    // reward related functions
    function getDaoRewardCheckpoints(bytes32 daoId)
        external
        view
        returns (RewardStorage.RewardCheckpoint[] memory rewardCheckpoints)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints;
    }

    function getDaoRewardCheckpoint(
        bytes32 daoId,
        uint256 index
    )
        external
        view
        returns (RewardStorage.RewardCheckpoint memory rewardCheckpoint)
    {
        return RewardStorage.layout().rewardInfos[daoId].rewardCheckpoints[index];
    }

    function getDaoRewardPendingRound(bytes32 daoId) external view returns (uint256 pendingRound) {
        return RewardStorage.layout().rewardInfos[daoId].rewardPendingRound;
    }

    function getDaoActiveRounds(bytes32 daoId) external view returns (uint256[] memory activeRounds) {
        return RewardStorage.layout().rewardInfos[daoId].activeRounds;
    }

    function getTotalWeight(bytes32 daoId, uint256 round) external view returns (uint256 totalWeight) {
        return RewardStorage.layout().rewardInfos[daoId].totalWeights[round];
    }

    function getProtocolWeight(bytes32 daoId, uint256 round) external view returns (uint256 protocolWeight) {
        return RewardStorage.layout().rewardInfos[daoId].protocolWeights[round];
    }

    function getDaoCreatorWeight(bytes32 daoId, uint256 round) external view returns (uint256 creatorWeight) {
        return RewardStorage.layout().rewardInfos[daoId].daoCreatorWeights[round];
    }

    function getCanvasCreatorWeight(
        bytes32 daoId,
        uint256 round,
        bytes32 canvasId
    )
        external
        view
        returns (uint256 creatorWeight)
    {
        return RewardStorage.layout().rewardInfos[daoId].canvasCreatorWeights[round][canvasId];
    }

    function getNftMinterWeight(
        bytes32 daoId,
        uint256 round,
        address nftMinter
    )
        external
        view
        returns (uint256 minterWeight)
    {
        return RewardStorage.layout().rewardInfos[daoId].nftMinterWeights[round][nftMinter];
    }

    function getDaoCreatorClaimableRound(bytes32 daoId) external view returns (uint256 claimableRound) {
        return RewardStorage.layout().rewardInfos[daoId].activeRounds[RewardStorage.layout().rewardInfos[daoId]
            .daoCreatorClaimableRoundIndex];
    }

    function getCanvasCreatorClaimableRound(
        bytes32 daoId,
        bytes32 canvasId
    )
        external
        view
        returns (uint256 claimableRound)
    {
        return RewardStorage.layout().rewardInfos[daoId].activeRounds[RewardStorage.layout().rewardInfos[daoId]
            .canvasCreatorClaimableRoundIndexes[canvasId]];
    }

    function getNftMinterClaimableRound(
        bytes32 daoId,
        address nftMinter
    )
        external
        view
        returns (uint256 claimableRound)
    {
        return RewardStorage.layout().rewardInfos[daoId].activeRounds[RewardStorage.layout().rewardInfos[daoId]
            .nftMinterClaimableRoundIndexes[nftMinter]];
    }

    function getDaoCreatorERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        uint256 daoCreatorERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].daoCreatorERC20RatioInBps;
        if (daoCreatorERC20RatioInBps == 0) {
            return settingsStorage.daoCreatorERC20RatioInBps;
        }
        return (daoCreatorERC20RatioInBps * (BASIS_POINT - settingsStorage.protocolERC20RatioInBps)) / BASIS_POINT;
    }

    function getCanvasCreatorERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage settingsStorage = SettingsStorage.layout();
        uint256 canvasCreatorERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].canvasCreatorERC20RatioInBps;
        if (canvasCreatorERC20RatioInBps == 0) {
            return settingsStorage.canvasCreatorERC20RatioInBps;
        }
        return (canvasCreatorERC20RatioInBps * (BASIS_POINT - settingsStorage.protocolERC20RatioInBps)) / BASIS_POINT;
    }

    function getNftMinterERC20Ratio(bytes32 daoId) public view returns (uint256) {
        return BASIS_POINT - SettingsStorage.layout().protocolERC20RatioInBps - getDaoCreatorERC20Ratio(daoId)
            - getCanvasCreatorERC20Ratio(daoId);
    }

    function getRoundReward(bytes32 daoId, uint256 round) public view returns (uint256) {
        return _castGetRoundRewardToView(_getRoundReward)(daoId, round);
    }

    function getRewardTillRound(bytes32 daoId, uint256 round) public view returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256[] memory activeRounds = rewardInfo.activeRounds;

        uint256 totalRoundReward;
        for (uint256 i; i < activeRounds.length && activeRounds[i] <= round;) {
            totalRoundReward += getRoundReward(daoId, activeRounds[i]);
            unchecked {
                ++i;
            }
        }

        return totalRoundReward;
    }

    function _getRoundReward(bytes32 daoId, uint256 round) internal returns (uint256) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        address rewardTemplate =
            SettingsStorage.layout().rewardTemplates[uint8(DaoStorage.layout().daoInfos[daoId].rewardTemplateType)];

        (bool succ, bytes memory data) = rewardTemplate.delegatecall(
            abi.encodeWithSelector(IRewardTemplate.getRoundIndex.selector, rewardInfo.activeRounds, round)
        );
        require(succ);
        uint256 roundIndex = abi.decode(data, (uint256));

        uint256 lastActiveRound =
            roundIndex == 0 ? rewardInfo.rewardCheckpoints[0].startRound : rewardInfo.activeRounds[roundIndex - 1];

        (succ, data) = rewardTemplate.delegatecall(
            abi.encodeWithSelector(IRewardTemplate.getRoundReward.selector, daoId, round, lastActiveRound)
        );
        require(succ);
        return abi.decode(data, (uint256));
    }

    function _castGetRoundRewardToView(function(bytes32, uint256) internal returns (uint256) fnIn)
        internal
        pure
        returns (function(bytes32, uint256) internal view returns (uint256) fnOut)
    {
        assembly {
            fnOut := fnIn
        }
    }
}

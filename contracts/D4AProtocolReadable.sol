// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { SettingsStorage } from "./storages/SettingsStorage.sol";
import { IPriceTemplate } from "./interface/IPriceTemplate.sol";
import { IRewardTemplate } from "./interface/IRewardTemplate.sol";

contract D4AProtocolReadable {
    /*////////////////////////////////////////////////
                         Getters                     
    ////////////////////////////////////////////////*/

    function getDaoMintCap(bytes32 daoId) public view returns (uint32) {
        return DaoStorage.layout().daoInfos[daoId].daoMintInfo.daoMintCap;
    }

    function getUserMintInfo(bytes32 daoId, address account) public view returns (uint32 minted, uint32 userMintCap) {
        minted = DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[account].minted;
        userMintCap = DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[account].mintCap;
    }

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

    function getCanvasIndex(bytes32 _canvas_id) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].index;
    }

    function getCanvasURI(bytes32 _canvas_id) public view returns (string memory) {
        return CanvasStorage.layout().canvasInfos[_canvas_id].canvasUri;
    }

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
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        return IPriceTemplate(l.priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)])
            .getCanvasNextPrice(pi.startRound, l.drb.currentRound(), pi.nftPriceFactor, daoFloorPrice, maxPrice, mintInfo);
    }

    function getCanvasCreatorERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 canvasCreatorERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].canvasCreatorERC20RatioInBps;
        if (canvasCreatorERC20RatioInBps == 0) {
            return l.canvasCreatorERC20RatioInBps;
        }
        return canvasCreatorERC20RatioInBps * (BASIS_POINT - l.protocolERC20RatioInBps - l.daoCreatorERC20RatioInBps)
            / BASIS_POINT;
    }

    function getNftMinterERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 nftMinterERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].nftMinterERC20RatioInBps;
        if (nftMinterERC20RatioInBps == 0) {
            return 0;
        }
        return nftMinterERC20RatioInBps * (BASIS_POINT - l.protocolERC20RatioInBps - l.daoCreatorERC20RatioInBps)
            / BASIS_POINT;
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

    function getProjectCanvasCount(bytes32 daoId) public view returns (uint256) {
        return DaoStorage.layout().daoInfos[daoId].canvases.length;
    }

    function getCanvasRebateRatioInBps(bytes32 canvasId) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasRebateRatioInBps;
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

    function getRoundReward(bytes32 daoId, uint256 round) public view returns (uint256) {
        return _castGetRoundRewardToView(_getRoundReward)(daoId, round);
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

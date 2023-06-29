// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { PriceTemplateType, RewardTemplateType } from "../interface/D4AEnums.sol";

library DaoStorage {
    struct DaoInfo {
        uint256 startRound;
        uint256 mintableRound;
        uint256 nftMaxSupply;
        uint256 nftTotalSupply;
        uint96 royaltyFeeInBps;
        uint256 daoIndex;
        address token;
        address nft;
        address daoFeePool;
        string daoUri;
        //from setting
        uint256 tokenMaxSupply;
        bytes32[] canvases;
        bool daoExist;
        uint256 nftPriceFactor;
        PriceTemplateType priceTemplateType;
        RewardTemplateType rewardTemplateType;
        uint256 daoFeePoolETHRatioInBps;
        uint256 daoFeePoolETHRatioInBpsFlatPrice;
    }

    struct Layout {
        mapping(bytes32 daoId => DaoInfo) daoInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.DaoStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

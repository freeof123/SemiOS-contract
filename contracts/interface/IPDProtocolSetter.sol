// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    UserMintCapParam,
    TemplateParam,
    Whitelist,
    Blacklist,
    SetDaoParam,
    NftMinterCapInfo,
    AllRatioForFundingParam
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { ID4AProtocolSetter } from "./ID4AProtocolSetter.sol";

interface IPDProtocolSetter is ID4AProtocolSetter {
    function setChildren(
        bytes32 daoId,
        bytes32[] calldata childrenDaoId,
        uint256[] calldata ratios,
        uint256 redeemPoolRatio,
        uint256 selfRewardRatio
    )
        external;
    function setRatioForFunding(bytes32 daoId, AllRatioForFundingParam calldata vars) external;

    function setInitialTokenSupplyForSubDao(bytes32 daoId, uint256 tokenMaxSupply) external;
}

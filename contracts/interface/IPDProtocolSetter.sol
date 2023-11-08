// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    UserMintCapParam,
    TemplateParam,
    Whitelist,
    Blacklist,
    SetDaoParam,
    NftMinterCapInfo,
    AllRatioForFundingParam,
    SetChildrenParam
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";
import { ID4AProtocolSetter } from "./ID4AProtocolSetter.sol";

interface IPDProtocolSetter is ID4AProtocolSetter {
    // ============================== Events =============================
    event ChildrenSet(
        bytes32 daoId,
        bytes32[] childrenDaoId,
        uint256[] erc20Ratios,
        uint256[] ethRatios,
        uint256 redeemPoolRatioETH,
        uint256 selfRewardRatioERC20,
        uint256 selfRewardRatioETH
    );

    event RatioForFundingSet(bytes32 daoId, AllRatioForFundingParam vars);

    event InitialTokenSupplyForSubDaoSet(bytes32 daoId, uint256 initialTokenSupply);

    function setChildren(bytes32 daoId, SetChildrenParam calldata vars) external;
    function setRatioForFunding(bytes32 daoId, AllRatioForFundingParam calldata vars) external;

    function setInitialTokenSupplyForSubDao(bytes32 daoId, uint256 tokenMaxSupply) external;
}

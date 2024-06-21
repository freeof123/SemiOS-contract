// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {
    UserMintCapParam,
    TemplateParam,
    Whitelist,
    Blacklist,
    SetDaoParam,
    NftMinterCapInfo,
    NftMinterCapIdInfo
} from "contracts/interface/D4AStructs.sol";
import { PriceTemplateType } from "contracts/interface/D4AEnums.sol";

interface ID4AProtocolSetter {
    event MintCapSet(
        bytes32 indexed daoId,
        uint32 daoMintCap,
        UserMintCapParam[] userMintCapParams,
        NftMinterCapInfo[] nftMinterCapInfo,
        NftMinterCapIdInfo[] nftMinterCapIdInfo
    );

    event DaoPriceTemplateSet(bytes32 indexed daoId, PriceTemplateType priceTemplateType, uint256 nftPriceFactor);

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    event DaoNftMaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    event DaoFloorPriceSet(bytes32 daoId, uint256 newFloorPrice);

    event DaoTemplateSet(bytes32 daoId, TemplateParam templateParam);

    event DaoRatioSet(
        bytes32 daoId,
        uint256 daoCreatorOutputRatio,
        uint256 canvasCreatorOutputRatio,
        uint256 nftMinterOutputRatio,
        uint256 daoFeePoolInputRatio,
        uint256 daoFeePoolInputRatioFlatPrice
    );

    event DailyMintCapSet(bytes32 indexed daoId, uint256 dailyMintCap);

    event DaoTokenSupplySet(bytes32 daoId, uint256 addedDaoToken);

    event WhiteListMintCapSet(bytes32 daoId, address whitelistUser, uint256 whitelistUserMintCap);

    event DaoUnifiedPriceSet(bytes32 daoId, uint256 newUnifiedPrice);

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        NftMinterCapInfo[] calldata nftMinterCapInfo,
        NftMinterCapIdInfo[] calldata nftMinterCapIdInfo,
        Whitelist memory whitelist,
        Blacklist memory blacklist,
        Blacklist memory unblacklist
    )
        external;

    function setDaoPriceTemplate(bytes32 daoId, PriceTemplateType priceTemplateType, uint256 priceFactor) external;

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) external;

    function setDaoFloorPrice(bytes32 daoId, uint256 newFloorPrice) external;

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) external;

    function setRoundMintCap(bytes32 daoId, uint256 roundMintCap) external;

    function setWhitelistMintCap(bytes32 daoId, address whitelistUser, uint32 whitelistUserMintCap) external;

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) external payable;

    function setDaoUnifiedPrice(bytes32 daoId, uint256 newUnifiedPrice) external;
}

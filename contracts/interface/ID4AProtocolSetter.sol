// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { UserMintCapParam, TemplateParam } from "contracts/interface/D4AStructs.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";

interface ID4AProtocolSetter {
    event MintCapSet(bytes32 indexed daoId, uint32 daoMintCap, UserMintCapParam[] userMintCapParams);

    event DaoNftPriceFactorSet(bytes32 daoId, uint256 newNftPriceMultiplyFactor);

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    event DaoNftMaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    event DaoFloorPriceSet(bytes32 daoId, uint256 newFloorPrice);

    event DaoTemplateSet(bytes32 daoId, TemplateParam templateParam);

    event DaoRatioSet(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    );

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        IPermissionControl.Whitelist memory whitelist,
        IPermissionControl.Blacklist memory blacklist,
        IPermissionControl.Blacklist memory unblacklist
    )
        external;

    function setDaoNftPriceFactor(bytes32 daoId, uint256 nftPriceFactor) external;

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) external;

    function setDaoMintableRound(bytes32 daoId, uint256 newMintableRound) external;

    function setDaoFloorPrice(bytes32 daoId, uint256 newFloorPrice) external;

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) external;

    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        external;

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) external;
}

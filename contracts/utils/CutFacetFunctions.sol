// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import { ID4ACreate } from "contracts/interface/ID4ACreate.sol";
import { IPDCreate } from "contracts/interface/IPDCreate.sol";
import { IPDBasicDao } from "contracts/interface/IPDBasicDao.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { IPDProtocolReadable } from "contracts/interface/IPDProtocolReadable.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { IPDProtocolSetter } from "contracts/interface/IPDProtocolSetter.sol";
import { IPDGrant } from "contracts/interface/IPDGrant.sol";
import { IPDRound } from "contracts/interface/IPDRound.sol";
import { IPDLock } from "contracts/interface/IPDLock.sol";

function getD4ACreateSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register D4ACreate
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = ID4ACreate.createProject.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ACreate.createOwnerProject.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ACreate.createCanvas.selector;
    assert(interfaceId == type(ID4ACreate).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getPDCreateSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register PDCreate
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = IPDCreate.createDao.selector;
    assert(interfaceId == type(IPDCreate).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getPDBasicDaoSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register PDCreate
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.unlock.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.ableToUnlock.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.getTurnover.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.isUnlocked.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.getCanvasIdOfSpecialNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.setSpecialTokenUriPrefix.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.getSpecialTokenUriPrefix.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.setBasicDaoNftFlatPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDBasicDao.getBasicDaoNftFlatPrice.selector;
    assert(interfaceId == type(IPDBasicDao).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getSettingsSelectors() pure returns (bytes4[] memory) {
    //------------------------------------------------------------------------------------------------------
    // settings facet cut
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register AccessControl
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = IAccessControl.getRoleAdmin.selector;
    interfaceId ^= selectors[selectorIndex++] = IAccessControl.grantRole.selector;
    interfaceId ^= selectors[selectorIndex++] = IAccessControl.hasRole.selector;
    interfaceId ^= selectors[selectorIndex++] = IAccessControl.renounceRole.selector;
    interfaceId ^= selectors[selectorIndex++] = IAccessControl.revokeRole.selector;
    assert(interfaceId == type(IAccessControl).interfaceId);
    // register D4ASettingsReadable
    interfaceId = 0;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.permissionControl.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.ownerProxy.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.mintProtocolFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.protocolFeePool.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.tradeProtocolFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.mintProjectFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.mintProjectFeeRatioFlatPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.ratioBase.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.createProjectFee.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.createCanvasFee.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.getPriceTemplates.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettingsReadable.getRewardTemplates.selector;
    assert(interfaceId == type(ID4ASettingsReadable).interfaceId);
    // register D4ASettings
    interfaceId = 0;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeCreateFee.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeProtocolFeePool.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeMintFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeTradeFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeERC20TotalSupply.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeERC20Ratio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeMaxMintableRounds.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.setMintableRounds.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeAddress.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeAssetPoolOwner.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeFloorPrices.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeMaxNFTAmounts.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeD4APause.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.setProjectPause.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.setCanvasPause.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.transferMembership.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.setTemplateAddress.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.setReservedDaoAmount.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.setRoyaltySplitterAndSwapFactoryAddress.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4ASettings.changeETHRewardRatio.selector;
    assert(interfaceId == type(ID4ASettings).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getProtocolReadableSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register D4AProtoclReadable
    bytes4 interfaceId;
    // legacy functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProjectCanvasAt.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProjectInfo.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProjectFloorPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProjectTokens.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasNFTCount.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getTokenIDAt.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasProject.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasURI.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProjectCanvasCount.selector;
    // new functions
    // DAO related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoStartBlock.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoMintableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoIndex.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoUri.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoFeePool.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoToken.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoTokenMaxSupply.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoNft.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoNftMaxSupply.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoNftTotalSupply.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoNftRoyaltyFeeRatioInBps.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoExist.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoCanvases.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoPriceTemplate.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoPriceFactor.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardTemplate.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoMintCap.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoNftHolderMintCap.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getUserMintInfo.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoTag.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRoundMintCap.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoUnifiedPriceModeOff.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoUnifiedPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoReserveNftNumber.selector;

    // canvas related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasDaoId.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasTokenIds.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasIndex.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasUri.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasRebateRatioInBps.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasExist.selector;
    // prices related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasLastPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoMaxPriceInfo.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoFloorPrice.selector;
    // reward related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoIsProgressiveJackpot.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoActiveRounds.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoCreatorClaimableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasCreatorClaimableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getNftMinterClaimableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getTotalWeight.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProtocolWeights.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoCreatorWeights.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasCreatorWeights.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getNftMinterWeights.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasNextPrice.selector;

    // protocol related functions
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getNFTTokenCanvas.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getLastestDaoIndex.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoId.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoAncestor.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoVersion.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getCanvasCreatorMintFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getAssetPoolMintFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getRedeemPoolMintFeeRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getCanvasCreatorMintFeeRatioFiatPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getAssetPoolMintFeeRatioFiatPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getRedeemPoolMintFeeRatioFiatPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getMinterERC20RewardRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getCanvasCreatorERC20RewardRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoCreatorERC20RewardRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getMinterETHRewardRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getCanvasCreatorETHRewardRatio.selector;
    // 1.3 related functions
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoCreatorETHRewardRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoAssetPool.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getIsAncestorDao.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoLastActiveRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoPassedRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoRemainingRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoChildren.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoChildrenRatiosERC20.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoChildrenRatiosETH.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoRedeemPoolRatioETH.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoSelfRewardRatioERC20.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoSelfRewardRatioETH.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoTopUpMode.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoIsThirdPartyToken.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getRoundERC20Reward.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getRoundETHReward.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getERC20RewardTillRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getETHRewardTillRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.royaltySplitters.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getCanvasNextPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoCirculateTokenAmount.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoRoundDistributeAmount.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoInfiniteMode.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoERC20PaymentMode.selector;
    //1.6 related functions
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoTopUpEthToRedeemPoolRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoTopUpErc20ToTreasuryRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoDefaultTopUpEthToRedeemPoolRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoDefaultTopUpErc20ToTreasuryRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoTreasuryNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoTreasury.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoEditInformationPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoEditParameterPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoEditStrategyPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoRewardPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getTreasuryTransferAssetPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getTreasurySetTopUpRatioPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getTreasuryEditInformationPermissionNft.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoEditInformationPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoEditParameterPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoEditStrategyPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getDaoRewardPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getTreasuryTransferAssetPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getTreasurySetTopUpRatioPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolReadable.getTreasuryEditInformationPermission.selector;

    assert(interfaceId == type(IPDProtocolReadable).interfaceId ^ type(ID4AProtocolReadable).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getProtocolSetterSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register D4AProtoclReadable
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setMintCapAndPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoPriceTemplate.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoNftMaxSupply.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoFloorPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setTemplate.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setCanvasRebateRatioInBps.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setRoundMintCap.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setWhitelistMintCap.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoUnifiedPrice.selector;

    //PDProtocal related functions

    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setChildren.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoParams.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoRemainingRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.changeDaoInfiniteMode.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoControlPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoEditInformationPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoEditParamPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoEditStrategyPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDaoRewardPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setTreasuryControlPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setTreasuryEditInformationPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setTreasuryTransferAssetPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setTreasurySetTopUpRatioPermission.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setTopUpBalanceSplitRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDProtocolSetter.setDefaultTopUpBalanceSplitRatio.selector;

    assert(interfaceId == type(IPDProtocolSetter).interfaceId ^ type(ID4AProtocolSetter).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getGrantSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register D4AGrant
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.addAllowedToken.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.removeAllowedToken.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.grantETH.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.grant.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.grantWithPermit.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.getVestingWallet.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.getAllowedTokensList.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.isTokenAllowed.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.grantDaoAssetPool.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDGrant.grantDaoAssetPoolWithPermit.selector;
    assert(interfaceId == type(IPDGrant).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getPDRoundSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register D4AGrant
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = IPDRound.getDaoCurrentRound.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDRound.setDaoDuation.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDRound.getDaoLastModifyBlock.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDRound.getDaoLastModifyRound.selector;

    assert(interfaceId == type(IPDRound).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

function getPDLockSelectors() pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](256);
    uint256 selectorIndex;
    // register D4AGrant
    bytes4 interfaceId;
    interfaceId ^= selectors[selectorIndex++] = IPDLock.lockTopUpNFT.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDLock.checkTopUpNftLockedStatus.selector;
    interfaceId ^= selectors[selectorIndex++] = IPDLock.getTopUpNftLockedInfo.selector;

    assert(interfaceId == type(IPDLock).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}
// 是否要添加selector

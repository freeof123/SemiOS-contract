// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IAccessControl } from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { ID4ASettingsReadable } from "contracts/D4ASettings/ID4ASettingsReadable.sol";
import { ID4ASettings } from "contracts/D4ASettings/D4ASettings.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { ID4AProtocolSetter } from "contracts/interface/ID4AProtocolSetter.sol";
import { ID4AGrant } from "contracts/interface/ID4AGrant.sol";

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
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoStartRound.selector;
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
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getUserMintInfo.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoFeePoolETHRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoFeePoolETHRatioFlatPrice.selector;
    // canvas related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasDaoId.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasTokenIds.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasIndex.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasUri.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasRebateRatioInBps.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasExist.selector;
    // prices related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasLastPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasNextPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoMaxPriceInfo.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoFloorPrice.selector;
    // reward related functions
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardStartRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardTotalRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoTotalReward.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardDecayFactor.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardIsProgressiveJackpot.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardLastActiveRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoRewardActiveRounds.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoCreatorClaimableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasCreatorClaimableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getNftMinterClaimableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getTotalWeight.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getProtocolWeight.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoCreatorWeight.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasCreatorWeight.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getNftMinterWeight.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getDaoCreatorERC20Ratio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getCanvasCreatorERC20Ratio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getNftMinterERC20Ratio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getRoundReward.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolReadable.getRewardTillRound.selector;
    assert(interfaceId == type(ID4AProtocolReadable).interfaceId);

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
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoParams.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoPriceTemplate.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoNftMaxSupply.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoMintableRound.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setDaoFloorPrice.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setTemplate.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setRatio.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AProtocolSetter.setCanvasRebateRatioInBps.selector;
    assert(interfaceId == type(ID4AProtocolSetter).interfaceId);

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
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.addAllowedToken.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.removeAllowedToken.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.grant.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.grantWithPermit.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.getVestingWallet.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.getAllowedTokensList.selector;
    interfaceId ^= selectors[selectorIndex++] = ID4AGrant.isTokenAllowed.selector;
    assert(interfaceId == type(ID4AGrant).interfaceId);

    /// @solidity memory-safe-assembly
    assembly {
        mstore(selectors, selectorIndex)
    }

    return selectors;
}

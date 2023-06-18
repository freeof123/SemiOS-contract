// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/Console2.sol";

import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import { IProtoDAOSettingsReadable, IProtoDAOSettingsWritable } from "contracts/ProtoDaoSettings/IProtoDAOSettings.sol";

import { D4AAddress } from "./utils/D4AAddress.sol";
import { D4ADiamond } from "contracts/D4ADiamond.sol";
import { ProtoDAOSettings } from "contracts/ProtoDAOSettings/ProtoDAOSettings.sol";

contract ProtoDAOSettingsScript is Script, D4AAddress {
    using stdJson for string;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    address public owner = vm.addr(deployerPrivateKey);

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        console2.log("\n================================================================================");
        console2.log("Start deploy ProtoDAOSettings");
        protoDaoSettings = new ProtoDAOSettings();
        vm.toString(address(protoDaoSettings)).write(path, ".D4AProtocolWithPermission.ProtoDAOSettings");
        console2.log("ProtoDAOSettings address: ", address(protoDaoSettings));
        console2.log("================================================================================\n");

        // console2.log("\n================================================================================");
        // console2.log("Start cut facets");
        // _cutFacetsProtoDaoSettings();
        // console2.log("================================================================================\n");

        console2.log("\n================================================================================");
        console2.log("Start replace facet address");
        _updateProtoDaoSettingsAddress();
        console2.log("================================================================================\n");

        vm.stopBroadcast();
    }

    function _cutFacetsProtoDaoSettings() internal {
        bytes4[] memory selectors = _getProtoDaoSettingsSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(protoDaoSettings),
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: selectors
        });

        D4ADiamond(payable(address(d4aProtocolWithPermission_proxy))).diamondCut(facetCuts, address(0), "");
    }

    function _updateProtoDaoSettingsAddress() internal {
        bytes4[] memory selectors = _getProtoDaoSettingsSelectors();

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);
        facetCuts[0] = IDiamondWritableInternal.FacetCut({
            target: address(protoDaoSettings),
            action: IDiamondWritableInternal.FacetCutAction.REPLACE,
            selectors: selectors
        });

        D4ADiamond(payable(address(d4aProtocolWithPermission_proxy))).diamondCut(facetCuts, address(0), "");
    }

    function _getProtoDaoSettingsSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        uint256 selectorIndex;
        // register ProtoDAOSettingsReadable
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getCanvasCreatorERC20Ratio.selector;
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getNftMinterERC20Ratio.selector;
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getDaoFeePoolETHRatio.selector;
        selectors[selectorIndex++] = IProtoDAOSettingsReadable.getDaoFeePoolETHRatioFlatPrice.selector;
        // register ProtoDAOSettingsWritable
        selectors[selectorIndex++] = IProtoDAOSettingsWritable.setRatio.selector;

        return selectors;
    }
}

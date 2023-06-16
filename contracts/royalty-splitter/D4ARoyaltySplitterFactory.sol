// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ID4ARoyaltySplitterFactory} from "../interface/ID4ARoyaltySplitterFactory.sol";
import {D4ARoyaltySplitter} from "./D4ARoyaltySplitter.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract D4ARoyaltySplitterFactory is ID4ARoyaltySplitterFactory, AutomationCompatibleInterface {
    using Clones for address;

    D4ARoyaltySplitter public impl;
    D4ARoyaltySplitter[] public royaltySplitters;
    address public uniswapV2Router;
    address public oracleRegistry;

    event NewD4ARoyaltySplitter(address addr);

    constructor(address WETH, address uniswapV2Router_, address oracleRegistry_) {
        impl = new D4ARoyaltySplitter(WETH);
        uniswapV2Router = uniswapV2Router_;
        oracleRegistry = oracleRegistry_;
    }

    function getSplittersLength() external view returns (uint256) {
        return royaltySplitters.length;
    }

    function createD4ARoyaltySplitter(
        address protocolFeePool,
        uint256 protocolShare,
        address daoFeePool,
        uint256 daoShare
    ) public returns (address) {
        D4ARoyaltySplitter t = D4ARoyaltySplitter(payable(address(impl).clone()));
        t.initialize(protocolFeePool, protocolShare, daoFeePool, daoShare, uniswapV2Router, oracleRegistry);
        t.transferOwnership(msg.sender);
        royaltySplitters.push(t);

        emit NewD4ARoyaltySplitter(address(t));
        return address(t);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 length = royaltySplitters.length;
        D4ARoyaltySplitter[] memory splitters = new D4ARoyaltySplitter[](length);
        bytes[] memory performDatas = new bytes[](length);
        uint256 counter;
        for (uint256 i = 0; i < length; ++i) {
            (bool upkeepNeeded_, bytes memory performData_) = royaltySplitters[i].checkUpkeep(checkData);
            if (upkeepNeeded_) {
                upkeepNeeded = true;
                splitters[counter] = royaltySplitters[i];
                performDatas[counter] = performData_;
                ++counter;
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            mstore(performDatas, counter)
            mstore(splitters, counter)
        }
        performData = abi.encode(splitters, performDatas);
    }

    function performUpkeep(bytes calldata performData) external {
        (D4ARoyaltySplitter[] memory splitters, bytes[] memory performDatas) =
            abi.decode(performData, (D4ARoyaltySplitter[], bytes[]));
        uint256 length = splitters.length;
        require(length == performDatas.length, "Invalid Length");
        for (uint256 i = 0; i < length;) {
            splitters[i].performUpkeep(performDatas[i]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AErrors.sol";

import "forge-std/Test.sol";

contract PDMainDaoOwnership is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_demo() public {
        CreateDaoParam memory param;
        // console2.log(daoCreator.addr);
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        bytes32 canvasId1 = param.canvasId;
        param.isBasicDao = true;
        param.topUpMode = false;
        param.infiniteMode = true;
        param.noPermission = true;
        param.mintableRound = 10;

        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);

        super._mintNft(
            daoId,
            canvasId1,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );

        param.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        param.existDaoId = daoId;
        param.isBasicDao = false;
        param.daoUri = "continuous dao uri";
        super._createDaoForFunding(param, daoCreator2.addr);
    }

    receive() external payable { }
}

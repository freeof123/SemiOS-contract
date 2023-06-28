// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import "contracts/interface/D4AStructs.sol";
import { IPermissionControl } from "contracts/interface/IPermissionControl.sol";
import { D4AAddress } from "script/utils/D4AAddress.sol";
import { D4ACreateProjectProxy } from "contracts/proxy/D4ACreateProjectProxy.sol";
import { D4AProtocol } from "contracts/D4AProtocol.sol";
import { MintNftSigUtils } from "./utils/MintNftSigUtils.sol";

contract V2Test is Test, D4AAddress {
    MintNftSigUtils public sigUtils;

    Account public actor = makeAccount("Actor");

    function setUp() public {
        vm.createSelectFork(vm.envString("GOERLI_RPC_URL"));
        sigUtils = new MintNftSigUtils(address(d4aProtocol_proxy));
    }

    function test_CreateDao() public {
        startHoax(actor.addr);
        // create trivial DAO
        uint256 startDrb = d4aDrb.currentRound();
        bytes32 daoId = D4ACreateProjectProxy(payable(address(d4aCreateProjectProxy_proxy))).createProject{
            value: 0.1 ether
        }(
            DaoMetadataParam(startDrb, 30, 0, 0, 750, "test project uri", 0),
            IPermissionControl.Whitelist({
                minterMerkleRoot: bytes32(0),
                minterNFTHolderPasses: new address[](0),
                canvasCreatorMerkleRoot: bytes32(0),
                canvasCreatorNFTHolderPasses: new address[](0)
            }),
            IPermissionControl.Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            DaoMintCapParam({ daoMintCap: 0, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam(7500, 2500, 3000, 3500),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            0
        );
        bytes32 canvasId = D4AProtocol(address(d4aProtocol_proxy)).createCanvas{ value: 0.01 ether }(
            daoId, "test canvas uri", new bytes32[](0), 0
        );
        string memory tokenUri = "test token uri";
        uint256 flatPrice = 0;
        bytes32 digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(actor.key, digest);
        uint256 tokenId = D4AProtocol(address(d4aProtocol_proxy)).mintNFT{ value: 0.1 ether }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        assertEq(tokenId, 1);

        vm.prank(0xe6046371B729f23206a94DDCace89FEceBBD565c);
        IAccessControl(address(d4aProtocol_proxy)).grantRole(keccak256("OPERATION_ROLE"), actor.addr);

        vm.startPrank(actor.addr);
        // create complex DAO
        daoId = D4ACreateProjectProxy(payable(address(d4aCreateProjectProxy_proxy))).createProject{ value: 0.1 ether }(
            DaoMetadataParam(startDrb, 30, 0, 0, 750, "test project uri 1", 42),
            IPermissionControl.Whitelist({
                minterMerkleRoot: bytes32(0),
                minterNFTHolderPasses: new address[](0),
                canvasCreatorMerkleRoot: bytes32(0),
                canvasCreatorNFTHolderPasses: new address[](0)
            }),
            IPermissionControl.Blacklist({ minterAccounts: new address[](0), canvasCreatorAccounts: new address[](0) }),
            DaoMintCapParam({ daoMintCap: 5, userMintCapParams: new UserMintCapParam[](0) }),
            DaoETHAndERC20SplitRatioParam(7500, 2500, 3000, 3500),
            TemplateParam({
                priceTemplateType: PriceTemplateType.EXPONENTIAL_PRICE_VARIATION,
                priceFactor: 20_000,
                rewardTemplateType: RewardTemplateType.LINEAR_REWARD_ISSUANCE,
                rewardDecayFactor: 0,
                rewardDecayLife: 1,
                isProgressiveJackpot: false
            }),
            31
        );
        canvasId = D4AProtocol(address(d4aProtocol_proxy)).createCanvas{ value: 0.01 ether }(
            daoId, "test canvas uri 1", new bytes32[](0), 0
        );
        tokenUri = "test token uri 1";
        flatPrice = 0;
        digest = sigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (v, r, s) = vm.sign(actor.key, digest);
        tokenId = D4AProtocol(address(d4aProtocol_proxy)).mintNFT{ value: 0.1 ether }(
            daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        );
        assertEq(tokenId, 1);
    }
}

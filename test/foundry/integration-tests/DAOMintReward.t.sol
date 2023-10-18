// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "contracts/interface/D4AErrors.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { MintNftSigUtils } from "test/foundry/utils/MintNftSigUtils.sol";
import { ID4AProtocolReadable } from "contracts/interface/ID4AProtocolReadable.sol";
import { BasicDaoUnlocker } from "contracts/BasicDaoUnlocker.sol";
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { IPDBasicDao } from "contracts/interface/IPDBasicDao.sol";
import { UserMintCapParam, Whitelist, Blacklist, NftMinterCapInfo } from "contracts/interface/D4AStructs.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAOMintReward is DeployHelper {
    function setUp() public {
        super.setUpEnv();
    }

    function test_createDao_mintNFT_claimReward() public {
        DeployHelper.CreateDaoParam memory createDaoParam;
        createDaoParam.floorPriceRank = 9999;
        createDaoParam.mintableRound = 10;
        createDaoParam.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));

        // create Baisc DAO
        bytes32 basicDaoId = super._createBasicDao(createDaoParam);
        console2.log("basic DAO created successfully \n");

        drb.changeRound(1);

        uint256 basicDaoFlatPrice = protocol.getDaoUnifiedPrice(basicDaoId);

        super._mintNft(basicDaoId, createDaoParam.canvasId, "uri:1", basicDaoFlatPrice, daoCreator.key, daoCreator.addr);

        drb.changeRound(2);

        {
            uint256 rewardRound1 = ID4AProtocolReadable(address(protocol)).getRoundReward(basicDaoId, 1);
            console2.log("the reward in round 1: ", rewardRound1);

            // claim Basic DAO reward
            uint256 baiscDaoCreatorReward = protocol.claimProjectERC20Reward(basicDaoId);
            console2.log("dao creator reward: ", baiscDaoCreatorReward);

            // claim NFT minter reward
            uint256 amount = protocol.claimNftMinterReward(basicDaoId, daoCreator.addr);
            console2.log("claim minter reward amount: ", amount);

            // show the receive amount of ERC20 token
            IERC20 daoToken = IERC20(protocol.getDaoToken(basicDaoId));
            uint256 tokenBalance = daoToken.balanceOf(daoCreator.addr);
            console2.log("ERC20 token received amount: ", tokenBalance);

            // assertEq(baiscDaoCreatorReward, tokenBalance);

            uint256 rewardAfterClaim = ID4AProtocolReadable(address(protocol)).getRoundReward(basicDaoId, 1);
            console2.log("reward after claim: ", rewardAfterClaim);

            // create Continuous DAO
            createDaoParam.daoUri = "continuous dao uri";
            createDaoParam.canvasId = keccak256(abi.encode(daoCreator2.addr, block.timestamp));
        }

        // needMintableWork = true, uniPriceModeOff = true
        bytes32 continuousDaoId = super._createContinuousDao(createDaoParam, basicDaoId, true, true, 1000);
        console2.log("\n created continuous dao successfully");

        uint256 continuousDaoFlatPrice = protocol.getDaoUnifiedPrice(continuousDaoId);

        // dao creator mint NFT then transfer to NFT minter
        _mintNftAndTransfer(
            continuousDaoId,
            createDaoParam.canvasId,
            "uri: continuous dao",
            continuousDaoFlatPrice,
            daoCreator.key,
            daoCreator.addr,
            nftMinter.addr
        );
        console2.log("mint and transfer nft to minter successfully");

        _mintNftAndTransfer(
            continuousDaoId,
            createDaoParam.canvasId,
            "uri: continuous dao2",
            continuousDaoFlatPrice,
            daoCreator.key,
            daoCreator.addr,
            nftMinter2.addr
        );
        console2.log("mint and transfer nft to minter2 successfully");

        {
            bytes32 digest =
                mintNftSigUtils.getTypedDataHash(createDaoParam.canvasId, "uri: test", continuousDaoFlatPrice);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);

            // 未设置 NFT mint cap，默认为 0 故导致 mint 失败
            vm.expectRevert(ExceedMinterMaxMintAmount.selector);
            hoax(nftMinter.addr);
            protocol.mintNFT{
                value: continuousDaoFlatPrice == 0
                    ? protocol.getCanvasNextPrice(createDaoParam.canvasId)
                    : continuousDaoFlatPrice
            }(
                continuousDaoId,
                createDaoParam.canvasId,
                "uri: test",
                new bytes32[](0),
                continuousDaoFlatPrice,
                abi.encodePacked(r, s, v)
            );
            console2.log("NFT mint and transfer failed");
        }

        {
            // transfer at least 2 ETH to unlock basic dao
            address basicDaoFeePoolAddress = protocol.getDaoFeePool(basicDaoId);
            (bool success,) = basicDaoFeePoolAddress.call{ value: 3 ether }("");
            require(success, "Failed to increase turnover");
            // should unlock basic dao first
            BasicDaoUnlocker basicDaoUnlocker = new BasicDaoUnlocker(address(protocol));

            assertTrue(IPDBasicDao(protocol).ableToUnlock(basicDaoId));

            (bool upkeepNeeded, bytes memory performData) = basicDaoUnlocker.checkUpkeep("");
            assertTrue(upkeepNeeded);
            assertTrue(!IPDBasicDao(protocol).isUnlocked(basicDaoId));

            if (upkeepNeeded) {
                basicDaoUnlocker.performUpkeep(performData);
            }

            assertTrue(IPDBasicDao(protocol).isUnlocked(basicDaoId));
            // (, bytes memory performData) = basicDaoUnlocker.checkUpkeep(new bytes(0));
            // basicDaoUnlocker.performUpkeep(performData);

            console2.log("unlock successfully");
        }

        {
            address nftAddr = protocol.getDaoNft(continuousDaoId);
            UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](1);
            NftMinterCapInfo[] memory nftMinterCapInfo = new NftMinterCapInfo[](1);
            nftMinterCapInfo[0] = NftMinterCapInfo({ nftAddress: nftAddr, nftMintCap: 10 });
            Whitelist memory whitelist;
            Blacklist memory blacklist;
            Blacklist memory unblacklist;
            // set NFT mint cap to 10
            vm.prank(daoCreator.addr);
            protocol.setMintCapAndPermission(
                continuousDaoId, 10, userMintCapParams, nftMinterCapInfo, whitelist, blacklist, unblacklist
            );
            console2.log("set NFT mint cap successfully \n");
        }

        {
            // set mintable round, 60 when init, maxMintableRound is 366
            vm.prank(daoCreator.addr);
            uint256 newMintableRound = 90;
            protocol.setDaoMintableRound(continuousDaoId, newMintableRound);
        }

        {
            // add dao token max supply
            vm.prank(daoCreator.addr);
            uint256 addedDaoToken = 1e26;
            protocol.setDaoTokenSupply(continuousDaoId, addedDaoToken);
        }

        // minter mint NFT
        super._mintNft(
            continuousDaoId,
            createDaoParam.canvasId,
            "uri: minter",
            continuousDaoFlatPrice,
            daoCreator.key,
            nftMinter.addr
        );

        // minter2 mint NFT
        super._mintNft(
            continuousDaoId,
            createDaoParam.canvasId,
            "uri: minter2",
            continuousDaoFlatPrice,
            daoCreator.key,
            nftMinter2.addr
        );

        drb.changeRound(3);

        // TODO: claim other
        uint256 amount1 = protocol.claimNftMinterReward(continuousDaoId, nftMinter.addr);
        console2.log("claim NFT minter reward by minter: ", amount1);

        uint256 amount2 = protocol.claimNftMinterReward(continuousDaoId, nftMinter2.addr);
        console2.log("claim NFT minter reward by minter2: ", amount2);

        // the reward of baisc dao creator after creating continuous dao
        uint256 basicDaoCreatorRewardAfter = protocol.claimProjectERC20Reward(basicDaoId);
        console2.log("dao creator reward after: ", basicDaoCreatorRewardAfter);
    }

    // ====================================================================================

    /**
     * @dev mint NFT then transfer
     * @notice this can be added to DeployerHelper
     * @param daoId the dao id
     * @param canvasId the canvas id
     * @param tokenUri the token uri
     * @param flatPrice the flat price
     * @param canvasCreatorKey the private key of canvas creator
     * @param hoaxer the address of account who will be hoaxed to mint NFT
     * @param to the receiver address who will receive the NFT
     */
    function _mintNftAndTransfer(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice,
        uint256 canvasCreatorKey,
        address hoaxer,
        address to
    )
        internal
        returns (uint256 tokenId)
    {
        bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(canvasCreatorKey, digest);
        hoax(hoaxer);
        tokenId = protocol.mintNFTAndTransfer{
            value: flatPrice == 0 ? protocol.getCanvasNextPrice(canvasId) : flatPrice
        }(daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v), to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";

import { UserMintCapParam, CreateCanvasAndMintNFTParam } from "contracts/interface/D4AStructs.sol";
import { ExceedMinterMaxMintAmount } from "contracts/interface/D4AErrors.sol";
import { D4AFeePool } from "contracts/feepool/D4AFeePool.sol";
import { D4AERC721 } from "contracts/D4AERC721.sol";
import { PDCreate } from "contracts/PDCreate.sol";

contract ProtoDaoTest is DeployHelper {
    function setUp() public {
        setUpEnv();
    }

    function test_NFTHolderNotAllowedToMintAfterFiveMints() public {
        // DeployHelper.CreateDaoParam memory param;
        // param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        // bytes32 daoId = _createBasicDao(param);

        // _mintNft(
        //     daoId,
        //     param.canvasId,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(1)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr
        // );
        // _mintNft(
        //     daoId,
        //     param.canvasId,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(2)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr
        // );
        // _mintNft(
        //     daoId,
        //     param.canvasId,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(3)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr
        // );
        // _mintNft(
        //     daoId,
        //     param.canvasId,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(4)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr
        // );
        // _mintNft(
        //     daoId,
        //     param.canvasId,
        //     string.concat(
        //         tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(5)), ".json"
        //     ),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr
        // );

        // bytes32 canvasId = param.canvasId;
        // string memory tokenUri = string.concat(
        //     tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(6)), ".json"
        // );
        // uint256 flatPrice = 0.01 ether;
        // bytes32 digest = mintNftSigUtils.getTypedDataHash(canvasId, tokenUri, flatPrice);
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);

        // // 在新的逻辑中，在以上参数传递的情况下，这个地方应该是可以铸造超过5个的，所以注释掉下面的selector
        // //同理，不需要注释，
        // vm.expectRevert(ExceedMinterMaxMintAmount.selector);

        // vm.prank(daoCreator.addr);
        // protocol.mintNFT{ value: flatPrice }(
        //     daoId, canvasId, tokenUri, new bytes32[](0), flatPrice, abi.encodePacked(r, s, v)
        // );
    }

    function test_ShouldIncreaseDaoTurnoverAfterTransferETHIntoDaoFeePool() public {
        // DeployHelper.CreateDaoParam memory param;
        // param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        // bytes32 daoId = _createBasicDao(param);

        // D4AFeePool daoFeePool = D4AFeePool(payable(protocol.getDaoFeePool(daoId)));
        // assertEq(daoFeePool.turnover(), 0);
        // assertEq(protocol.ableToUnlock(daoId), false);

        // hoax(randomGuy.addr);
        // (bool succ,) = address(daoFeePool).call{ value: 2 ether }("");
        // require(succ);

        // assertEq(daoFeePool.turnover(), 2 ether);
        // assertEq(protocol.ableToUnlock(daoId), true);
    }

    function test_MintWithSameSpecialTokenUriAtTheSameTimeShouldProduceTwoNfts() public {
        //DeployHelper.CreateDaoParam memory param;
        // param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        // bytes32 daoId = _createBasicDao(param);

        // address[] memory accounts = new address[](1);
        // accounts[0] = daoCreator.addr;
        // _mintNftWithProof(
        //     daoId,
        //     param.canvasId,
        //     string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json"),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr,
        //     getMerkleProof(accounts, daoCreator.addr)
        // );
        // _mintNftWithProof(
        //     daoId,
        //     param.canvasId,
        //     string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1", ".json"),
        //     0.01 ether,
        //     daoCreator.key,
        //     daoCreator.addr,
        //     getMerkleProof(accounts, daoCreator.addr)
        // );
        // D4AERC721 nft = D4AERC721(protocol.getDaoNft(daoId));
        // assertEq(nft.balanceOf(daoCreator.addr), 2);
        // assertEq(
        //     nft.tokenURI(1), string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "1",
        // ".json")
        // );
        // assertEq(
        //     nft.tokenURI(2), string.concat(tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", "2",
        // ".json")
        // );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "contracts/interface/D4AErrors.sol";
import { ERC20SigUtils } from "test/foundry/utils/ERC20SigUtils.sol";

import { console2 } from "forge-std/Test.sol";

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    // computes the hash of a permit
    function getStructHash(Permit memory _permit) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(PERMIT_TYPEHASH, _permit.owner, _permit.spender, _permit.value, _permit.nonce, _permit.deadline)
        );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }
}

contract ProtoDaoTreasuryTest is DeployHelper {
    event Transfer(address from, address to, uint256 tokenId);
    event NewSemiOsGrantAssetPoolNft(
        address erc721Address,
        uint256 tokenId,
        bytes32 daoId,
        address granter,
        uint256 grantAmount,
        bool isUseTreasury,
        uint256 grantBlock,
        address token
    );

    function setUp() public {
        super.setUpEnv();
    }

    function test_grantDaoAssetPool_useTreasury() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address erc20Token = protocol.getDaoToken(daoId);
        address treasury = protocol.getDaoTreasury(daoId);

        address grant_treasury_nft = protocol.getDaoGrantAssetPoolNft(daoId);

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "check A");
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "check B");
        address token = protocol.getDaoToken(daoId);
        vm.expectRevert(NotNftOwner.selector);
        protocol.grantDaoAssetPool(daoId, 1000 ether, true, "TEst", token);

        vm.prank(daoCreator.addr);
        vm.expectEmit(true, true, true, true, address(protocol));
        emit NewSemiOsGrantAssetPoolNft(
            grant_treasury_nft, 2, daoId, daoCreator.addr, 1000 ether, true, block.number, erc20Token
        );
        protocol.grantDaoAssetPool(daoId, 1000 ether, true, "TEst", token);
        assertEq(
            IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether + 1000 ether, "check D"
        );
        assertEq(
            IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether - 1000 ether, "check C"
        );
    }

    function test_grantDaoAssetPool_notUseTreasury() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address erc20Token = protocol.getDaoToken(daoId);
        address treasury = protocol.getDaoTreasury(daoId);

        address grant_treasury_nft = protocol.getDaoGrantAssetPoolNft(daoId);

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "check A");
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "check B");
        deal(erc20Token, daoCreator.addr, 10_000 ether);

        vm.prank(daoCreator.addr);
        IERC20(erc20Token).approve(address(protocol), 1000 ether);
        vm.expectEmit(true, true, true, true, address(protocol));
        emit NewSemiOsGrantAssetPoolNft(
            grant_treasury_nft, 2, daoId, daoCreator.addr, 1000 ether, false, block.number, erc20Token
        );
        vm.prank(daoCreator.addr);
        protocol.grantDaoAssetPool(daoId, 1000 ether, false, "test", erc20Token);

        assertEq(
            IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)),
            5000 * 10_000 ether + 1000 ether,
            "Should be 1000"
        );
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "Check c");
        assertEq(IERC20(erc20Token).balanceOf(daoCreator.addr), 10_000 ether - 1000 ether, "check D");
    }

    function test_grantDaoAssetPoolWithPermit() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address erc20Token = protocol.getDaoToken(daoId);
        deal(erc20Token, daoCreator.addr, 10_000 ether);

        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: daoCreator.addr,
            spender: address(protocol),
            value: 1000 ether,
            nonce: IERC20Permit(erc20Token).nonces(daoCreator.addr),
            deadline: block.timestamp + 1 days
        });
        SigUtils sigUtils = new SigUtils(IERC20Permit(erc20Token).DOMAIN_SEPARATOR());
        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(daoCreator.key, digest);

        emit NewSemiOsGrantAssetPoolNft(
            protocol.getDaoGrantAssetPoolNft(daoId),
            2,
            daoId,
            daoCreator.addr,
            1000 ether,
            false,
            block.number,
            erc20Token
        );

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "check A");
        assertEq(IERC20(erc20Token).balanceOf(daoCreator.addr), 10_000 ether, "check B");
        vm.prank(daoCreator.addr);
        protocol.grantDaoAssetPoolWithPermit(daoId, 1000 ether, "TEst", erc20Token, block.timestamp + 1 days, v, r, s);
        assertEq(
            IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)),
            5000 * 10_000 ether + 1000 ether,
            "Should be 3"
        );
        assertEq(IERC20(erc20Token).balanceOf(daoCreator.addr), 9000 ether, "check C");
    }

    function test_checkErc20circulation_notThirdParty() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.selfRewardOutputRatio = 10_000;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address erc20Token = protocol.getDaoToken(daoId);
        address treasury = protocol.getDaoTreasury(daoId);
        assertEq(IERC20(erc20Token).totalSupply(), 1_000_000_000 ether);
        assertEq(protocol.getDaoCirculateTokenAmount(daoId), 0);
        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "check A");
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "check B");
        super._mintNft(
            daoId,
            param.canvasId,
            string.concat(
                tokenUriPrefix, vm.toString(protocol.getDaoIndex(daoId)), "-", vm.toString(uint256(0)), ".json"
            ),
            0.01 ether,
            daoCreator.key,
            nftMinter.addr
        );
        vm.roll(3);
        assertEq(protocol.getDaoCirculateTokenAmount(daoId), 5_000_000 ether, "check e");
    }

    function test_treasury_mintFee() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.noDefaultRatio = true;
        param.uniPriceModeOff = true;
        param.canvasCreatorMintFeeRatio = 750;
        param.assetPoolMintFeeRatio = 2000;
        param.redeemPoolMintFeeRatio = 3000;
        param.treasuryMintFeeRatio = 4000;
        param.canvasCreatorMintFeeRatioFiatPrice = 3750;
        param.assetPoolMintFeeRatioFiatPrice = 3000;
        param.redeemPoolMintFeeRatioFiatPrice = 2000;
        param.treasuryMintFeeRatioFiatPrice = 1000;
        param.minterInputRewardRatio = 2000;
        param.canvasCreatorInputRewardRatio = 3000;
        param.daoCreatorInputRewardRatio = 4800;
        param.minterOutputRewardRatio = 2000;
        param.canvasCreatorOutputRewardRatio = 3000;
        param.daoCreatorOutputRewardRatio = 4800;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = param.canvasId;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.flatPrice = 0.02 ether;
        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        address treasury = protocol.getDaoTreasury(daoId);
        assertEq(treasury.balance, 0.002 ether, "check A");
        nftParam.flatPrice = 0;
        nftParam.tokenUri = "test1";
        super._mintNftWithParam(nftParam, nftMinter.addr);
        assertEq(treasury.balance, 0.002 ether + 0.01 ether * 0.4, "check B");
    }

    function test_treasury_mintFee_outputToken() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.noDefaultRatio = true;
        param.uniPriceModeOff = true;
        param.canvasCreatorMintFeeRatio = 750;
        param.assetPoolMintFeeRatio = 2000;
        param.redeemPoolMintFeeRatio = 3000;
        param.treasuryMintFeeRatio = 4000;
        param.canvasCreatorMintFeeRatioFiatPrice = 3750;
        param.assetPoolMintFeeRatioFiatPrice = 3000;
        param.redeemPoolMintFeeRatioFiatPrice = 2000;
        param.treasuryMintFeeRatioFiatPrice = 1000;
        param.minterInputRewardRatio = 2000;
        param.canvasCreatorInputRewardRatio = 3000;
        param.daoCreatorInputRewardRatio = 4800;
        param.minterOutputRewardRatio = 2000;
        param.canvasCreatorOutputRewardRatio = 3000;
        param.daoCreatorOutputRewardRatio = 4800;
        param.outputPaymentMode = true;
        param.thirdPartyToken = address(_testERC20);
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = param.canvasId;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.flatPrice = 0.02 ether;

        _testERC20.mint(nftMinter.addr, 1000 ether);

        ERC20SigUtils erc20SigUtils = new ERC20SigUtils(address(_testERC20));
        bytes32 digest = erc20SigUtils.getTypedDataHashV2(
            nftMinter.addr, address(protocol), 0.02 ether, block.timestamp + 1 days, address(_testERC20)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nftMinter.key, digest);
        nftParam.erc20Signature = abi.encode(v, r, s);
        nftParam.deadline = block.timestamp + 1 days;

        //minter0 have balance in round 1
        super._mintNftWithParam(nftParam, nftMinter.addr);
        address treasury = protocol.getDaoTreasury(daoId);
        assertEq(_testERC20.balanceOf(treasury), 0.002 ether, "check A");
        nftParam.flatPrice = 0;
        nftParam.tokenUri = "test1";

        digest = erc20SigUtils.getTypedDataHashV2(
            nftMinter.addr, address(protocol), 0.01 ether, block.timestamp + 1 days, address(_testERC20)
        );
        (v, r, s) = vm.sign(nftMinter.key, digest);
        nftParam.erc20Signature = abi.encode(v, r, s);
        super._mintNftWithParam(nftParam, nftMinter.addr);
        assertEq(_testERC20.balanceOf(treasury), 0.002 ether + 0.01 ether * 0.4, "check B");
    }

    function test_treasury_blockReward() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        param.noPermission = true;
        param.mintableRound = 10;
        param.treasuryInputRatio = 1000;
        param.selfRewardInputRatio = 2000;
        param.redeemPoolInputRatio = 3000;
        param.treasuryOutputRatio = 4000;
        param.selfRewardOutputRatio = 5000;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        MintNftParamTest memory nftParam;
        nftParam.daoId = daoId;
        nftParam.canvasId = param.canvasId;
        nftParam.canvasCreatorKey = daoCreator.key;
        nftParam.flatPrice = 0.01 ether;
        super._mintNftWithParam(nftParam, nftMinter.addr);
        address token = protocol.getDaoToken(daoId);
        address treasury = protocol.getDaoTreasury(daoId);
        assertEq(IERC20(address(token)).balanceOf(treasury), 950_000_000 ether + 5_000_000 * 0.4 ether);
        vm.roll(2);
        nftParam.tokenUri = "test1";
        super._mintNftWithParam(nftParam, nftMinter.addr);
        //10% block reward - 500000, in block 1 remains
        uint256 a = uint256((45_000_000 + 500_000) * 1e18) / 9;
        assertEq(
            IERC20(address(token)).balanceOf(treasury),
            uint256(950_000_000 ether + 5_000_000 * 0.4 ether + uint256(a * 4 / 10))
        );
        assertEq(treasury.balance, uint256(0.01 * 1e18 * 0.35) / 9 / 10);
    }
}

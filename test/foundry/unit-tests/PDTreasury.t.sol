import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "contracts/interface/D4AErrors.sol";

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

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "Should be 0");
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "Should be 1b");
        vm.expectRevert(NotNftOwner.selector);
        protocol.grantDaoAssetPool(daoId, 1000 ether, true, "TEst");

        vm.prank(daoCreator.addr);
        vm.expectEmit(true, true, true, true, address(protocol));
        emit NewSemiOsGrantAssetPoolNft(
            grant_treasury_nft, 2, daoId, daoCreator.addr, 1000 ether, true, block.number, erc20Token
        );
        protocol.grantDaoAssetPool(daoId, 1000 ether, true, "TEst");
        assertEq(
            IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)),
            5000 * 10_000 ether + 1000 ether,
            "Should be 1000"
        );
        assertEq(
            IERC20(erc20Token).balanceOf(treasury),
            1_000_000_000 ether - 5000 * 10_000 ether - 1000 ether,
            "Should be 1b sub 1000"
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

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "Should be 0");
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "Should be 1b");
        deal(erc20Token, daoCreator.addr, 10_000 ether);

        vm.prank(daoCreator.addr);
        IERC20(erc20Token).approve(address(protocol), 1000 ether);
        vm.expectEmit(true, true, true, true, address(protocol));
        emit NewSemiOsGrantAssetPoolNft(
            grant_treasury_nft, 2, daoId, daoCreator.addr, 1000 ether, false, block.number, erc20Token
        );
        vm.prank(daoCreator.addr);
        protocol.grantDaoAssetPool(daoId, 1000 ether, false, "TEst");
        assertEq(
            IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)),
            5000 * 10_000 ether + 1000 ether,
            "Should be 1000"
        );
        assertEq(
            IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "Should be 1b sub 1000"
        );
        assertEq(IERC20(erc20Token).balanceOf(daoCreator.addr), 10_000 ether - 1000 ether, "Should be 9000");
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

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "Should be 1");
        assertEq(IERC20(erc20Token).balanceOf(daoCreator.addr), 10_000 ether, "Should be 2");
        vm.prank(daoCreator.addr);
        protocol.grantDaoAssetPoolWithPermit(daoId, 1000 ether, "TEst", block.timestamp + 1 days, v, r, s);
        assertEq(
            IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)),
            5000 * 10_000 ether + 1000 ether,
            "Should be 3"
        );
        assertEq(IERC20(erc20Token).balanceOf(daoCreator.addr), 9000 ether, "Should be 4");
    }
}

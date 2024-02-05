import { DeployHelper } from "test/foundry/utils/DeployHelper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interface/D4AErrors.sol";

contract ProtoDaoTreasuryTest is DeployHelper {
    event Transfer(address from, address to, uint256 tokenId);
    event NewSemiOsGrantNft(
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

    function test_grantDaoAssetPool() public {
        DeployHelper.CreateDaoParam memory param;
        param.canvasId = keccak256(abi.encode(daoCreator.addr, block.timestamp));
        param.isBasicDao = true;
        bytes32 daoId = super._createDaoForFunding(param, daoCreator.addr);
        address erc20Token = protocol.getDaoToken(daoId);
        address treasury = protocol.getDaoTreasury(daoId);

        address grant_treasury_nft = protocol.getDaoTreasuryNft(daoId);

        assertEq(IERC20(erc20Token).balanceOf(protocol.getDaoAssetPool(daoId)), 5000 * 10_000 ether, "Should be 0");
        assertEq(IERC20(erc20Token).balanceOf(treasury), 1_000_000_000 ether - 5000 * 10_000 ether, "Should be 1b");
        vm.expectRevert(NotNftOwner.selector);
        protocol.grantDaoAssetPool(daoId, 1000 ether, true, "TEst");

        vm.prank(daoCreator.addr);
        vm.expectEmit(true, true, true, true, address(protocol));
        emit NewSemiOsGrantNft(
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
}

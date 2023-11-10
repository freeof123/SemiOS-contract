// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../utils/DeployHelper.sol";
import "script/utils/D4AAddress.sol";
import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AEnums.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

contract ErrorTest is Test, D4AAddress, EIP712 {
    bytes32 internal constant _MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    function setUp() public {
        //vm.createSelectFork(vm.envString("GOERLI_RPC_URL"));
        vm.createSelectFork("http://61.48.133.168:7545");

        //  vm.startPrank(0xe6046371B729f23206a94DDCace89FEceBBD565c);
        //  _deployLinearRewardIssuance();
        //  _deployExponentialRewardIssuance();

        //  vm.stopPrank();
    }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "ProtoDaoProtocol";
        version = "1";
    }

    function _verifySignature(
        bytes32 daoId,
        bytes32 canvasId,
        string memory tokenUri,
        uint256 nftFlatPrice,
        bytes memory signature
    )
        internal
        view
    {
        // check for special token URIs first
        bytes32 digest =
            _hashTypedData(keccak256(abi.encode(_MINTNFT_TYPEHASH, canvasId, keccak256(bytes(tokenUri)), nftFlatPrice)));
        address signer = ECDSAUpgradeable.recover(digest, signature);
        console2.log("signer:", signer);
    }

    // function test_signature() public{
    //     bytes32 daoId = 0x841adf0cf7c4e096f097d8e5bb214b9f0f96e62df65f0b2cf16f2c928627cb6d;
    //     bytes32 cavansId = 0x67caa0fb555696f9eb81228120f3501f23e6a41a8dd2112ca3ed8ff690ef8169;
    //     string memory tokenUri =
    // "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/work/W16957276420377963.json";
    //     uint256 nftFlatPrice = 0;
    //     _verifySignature(daoId, cavansId, tokenUri, nftFlatPrice,
    // hex"e929948fd68ea44e63f2f10553e358694fb13fd2082c18cfbd2ea7e47582ec022220ee0cdebf7ca6e800bd775f8bf9573e276a05310688cd5b89e666cf1bd1801b");
    // }

    // function test_mint1() public {
    //     vm.prank(0xb90B90225E628188A16C1ab2FfbD8372E49b39df);
    //     pdProtocol_proxy.createCanvasAndMintNFT(
    //         0x764a2fd001468cf0e3672a57535e2c4563363eb864671bed2a1d8951bd0ac1c1,
    //         0xdec3e394363ec2bcab5285cd07e157d030e3c8e8bd3bebd62a75390f7ca40fe4,
    //         "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/canvas/0xdec3e394363ec2bcab5285cd07e157d030e3c8e8bd3bebd62a75390f7ca40fe4.json",
    //         0xb90B90225E628188A16C1ab2FfbD8372E49b39df,
    //         "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/work/W16956338139541015.json",
    //         "0xe7d110918bdf9b0b01d936dd03ab3d381e2d85b37b3b91dd3d8e7e4fb95eb7745b760381cb055834cee464111329e7848ec86a27a3b1a39e90f457aa7575a7ae1c"
    //     );
    //     bytes memory b =
    // "0xe929948fd68ea44e63f2f10553e358694fb13fd2082c18cfbd2ea7e47582ec022220ee0cdebf7ca6e800bd775f8bf9573e276a05310688cd5b89e666cf1bd1801b";
    //     console2.log(b.length);
    // }

    // function test_create() public {
    //     vm.prank(0xf8BAf7268F3daeFE4135F7711473aE8b6c3b47d8);
    //     UserMintCapParam[] memory userMintCapParams = new UserMintCapParam[](1);
    //     userMintCapParams[0] = UserMintCapParam({ minter: 0xf8BAf7268F3daeFE4135F7711473aE8b6c3b47d8, mintCap: 5 });
    //     pdCreateProjectProxy_proxy.createContinuousDao(
    //         0x841adf0cf7c4e096f097d8e5bb214b9f0f96e62df65f0b2cf16f2c928627cb6d,
    //         DaoMetadataParam(
    //             8156,
    //             90,
    //             1,
    //             1,
    //             750,
    //             "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/dao/VJrDhxCZJYem2yklK3o1Q64716.json",
    //             0
    //         ),
    //         Whitelist(
    //             0x0000000000000000000000000000000000000000000000000000000000000000,
    //             new address[](0),
    //             0x0000000000000000000000000000000000000000000000000000000000000000,
    //             new address[](0)
    //         ),
    //         Blacklist(new address[](0), new address[](0)),
    //         DaoMintCapParam(0, userMintCapParams),
    //         DaoETHAndERC20SplitRatioParam(4800, 2500, 2500, 250, 300),
    //         TemplateParam(PriceTemplateType(1), 100000000000000, RewardTemplateType(0), 0, false),
    //         BasicDaoParam(
    //             500,
    //             0xd2e8bf0614882090acead26ae646ff02e928a29011d89bbd2041dd017f975796,
    //             "https://test-protodao.s3.ap-southeast-1.amazonaws.com/meta/canvas/d2e8bf0614882090acead26ae646ff02e928a29011d89bbd2041dd017f975796.json",
    //             "ss"
    //         ),
    //         16,
    //         false,
    //         100
    //     );
    // }

    function test_setParams() public {
        //vm.roll(9_853_009);
        pdProtocol_proxy = PDProtocol(0x7913B7a2cd48440005148799f6fA4E72A3f48B4f);
        SetDaoParam memory vars = SetDaoParam(
            0x83ca3c33ce4c1e4140fa2e00774f14c7f36655c34f9a0ad6babf0a4ce07cf2b3,
            2,
            1,
            0,
            PriceTemplateType(0),
            20_000,
            0,
            0,
            9800,
            9750,
            9750,
            2,
            0,
            1_000_000_000_000_000_000
        ); // 其中的枚举类型之前参数为 0
        vm.prank(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        PDProtocolSetter(address(pdProtocol_proxy)).setDaoParams(vars);
    }
}

// (0x780d0c7f45e4ab656c7adee7d61a0941ab4b87eed95fbb695c8d2298c7344141,2,1,0, 0, 20000, 4800, 2500, 2500, 9750, 9750,
// 10000, 0)

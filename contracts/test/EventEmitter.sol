// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AEnums.sol";

contract EventEmitter {
    event D4AMintNFT(bytes32 daoId, bytes32 canvasId, uint256 tokenId, string tokenUri, uint256 price);

    event CreateProjectParamEmittedForFunding(
        bytes32 daoId,
        address daoFeePool,
        address token,
        address nft,
        DaoMetadataParam daoMetadataParam,
        Whitelist whitelist,
        Blacklist blacklist,
        DaoMintCapParam daoMintCapParam,
        NftMinterCapInfo[] nftMinterCapInfo,
        TemplateParam templateParam,
        BasicDaoParam basicDaoParam,
        uint256 actionType,
        AllRatioForFundingParam allRatioForFundingParam
    );

    event CreateContinuousProjectParamEmittedForFunding(
        bytes32 existDaoId,
        bytes32 daoId,
        uint256 dailyMintCap,
        bool needMintableWork,
        bool unifiedPriceModeOff,
        uint256 unifiedPrice,
        uint256 reserveNftNumber,
        bool topUpMode
    );

    event NewProjectForFunding(
        bytes32 daoId,
        string daoUri,
        address daoFeePool,
        address token,
        address nft,
        uint256 royaltyFeeRatioInBps,
        bool isAncestorDao
    );

    event NewCanvasForFunding(bytes32 daoId, bytes32 canvasId, string canvasUri);

    event NewPoolsForFunding(
        address daoAssetPool, address daoRedeemPool, address daoFundingPool, bool isThirdPartyToken
    );

    event ChildrenSet(
        bytes32 daoId,
        bytes32[] childrenDaoId,
        uint256[] erc20Ratios,
        uint256[] ethRatios,
        uint256 redeemPoolRatioETH,
        uint256 selfRewardRatioERC20,
        uint256 selfRewardRatioETH
    );

    event RatioForFundingSet(bytes32 daoId, AllRatioForFundingParam vars);

    event InitialTokenSupplyForSubDaoSet(bytes32 daoId, uint256 initialTokenSupply);

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    event DaoNftMaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    event DailyMintCapSet(bytes32 indexed daoId, uint256 dailyMintCap);

    event DaoFloorPriceSet(bytes32 daoId, uint256 newFloorPrice);

    event DaoUnifiedPriceSet(bytes32 daoId, uint256 newUnifiedPrice);

    event DaoPriceTemplateSet(bytes32 indexed daoId, PriceTemplateType priceTemplateType, uint256 nftPriceFactor);

    event DaoBlockRewardDistributedToChildrenDao(
        bytes32 fromDaoId, bytes32 toDaoId, address token, uint256 amount, uint256 round
    );

    event DaoBlockRewardDistributedToRedeemPool(
        bytes32 fromDaoId, address redeemPool, address token, uint256 amount, uint256 round
    );

    event DaoBlockRewardForSelf(bytes32 daoId, address token, uint256 amount, uint256 round);

    event TopUpAmountUsed(address owner, bytes32 daoId, address redeemPool, uint256 erc20Amount, uint256 ethAmount);

    event MintFeeSplitted(
        bytes32 daoId,
        address daoRedeemPool,
        uint256 redeemPoolFee,
        address canvasOwner,
        uint256 canvasCreatorFee,
        address daoAssetPool,
        uint256 assetPoolFee
    );

    event PDClaimDaoCreatorReward(bytes32 daoId, address token, uint256 erc20Amount, uint256 ethAmount);

    event PDClaimCanvasReward(bytes32 daoId, bytes32 canvasId, address token, uint256 erc20Amount, uint256 ethAmount);

    event PDClaimNftMinterReward(bytes32 daoId, address token, uint256 erc20Amount, uint256 ethAmount);

    event PDClaimNftMinterRewardTopUp(bytes32 daoId, address token, uint256 erc20Amount, uint256 ethAmount);

    constructor() {
        address[] memory zeroAddressArray = new address[](0);
        bytes32[] memory zeroBytes32Array = new bytes32[](0);
        uint256[] memory zeroUintArray = new uint256[](0);

        UserMintCapParam[] memory userMintCapParam = new UserMintCapParam[](1);
        userMintCapParam[0] = UserMintCapParam(0xfde7a05310B5c14E628f11C15a8Cad6fcBd1C398, 5);
        NftMinterCapInfo[] memory nftMinterCapInfo = new NftMinterCapInfo[](1);
        nftMinterCapInfo[0] = NftMinterCapInfo(0x0000000000000000000000000000000000000000, 5);

        //create dao events

        emit CreateContinuousProjectParamEmittedForFunding(
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986,
            100,
            false,
            true,
            10_000_000_000_000_000,
            0,
            false
        );

        emit CreateProjectParamEmittedForFunding(
            0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986,
            0xc9c8a2A73d591B1411Acbbf5423CCEEdF36F8e97,
            0xe6342d41b9Fa0b899705354EFfC45736079C7131,
            0x0a42d4714Af9600844482087c5A17Dcd28E94b0e,
            DaoMetadataParam(1, 60, 0, 2, 1250, "test dao uri", 0),
            Whitelist(
                0x357d85896d1f85a5facf8f42da91aee7b1cf0b826b71d4cc3213beb0e077af3d,
                zeroAddressArray,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                zeroAddressArray
            ),
            Blacklist(zeroAddressArray, zeroAddressArray),
            DaoMintCapParam(0, userMintCapParam),
            nftMinterCapInfo,
            TemplateParam(PriceTemplateType(0), 20_000, RewardTemplateType(0), 0, false),
            BasicDaoParam(
                500,
                0xc6b344799718aec19d11a2e79c92e2843d897c56f1cd1cfed5f77dd1d18b5d65,
                "test dao creator canvas uri",
                "test dao"
            ),
            20,
            AllRatioForFundingParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000)
        );

        emit NewProjectForFunding(
            0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986,
            "test dao uri",
            0xc9c8a2A73d591B1411Acbbf5423CCEEdF36F8e97,
            0xe6342d41b9Fa0b899705354EFfC45736079C7131,
            0x0a42d4714Af9600844482087c5A17Dcd28E94b0e,
            1250,
            true
        );

        emit NewCanvasForFunding(
            0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986,
            0xc6b344799718aec19d11a2e79c92e2843d897c56f1cd1cfed5f77dd1d18b5d65,
            "test dao creator canvas uri"
        );

        emit NewPoolsForFunding(
            0x1b6cF3C12Fc589E98BD60857577F73C37ce6186f,
            0xc9c8a2A73d591B1411Acbbf5423CCEEdF36F8e97,
            0x0000000000000000000000000000000000000000,
            false
        );

        emit ChildrenSet(
            0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986,
            zeroBytes32Array,
            zeroUintArray,
            zeroUintArray,
            0,
            0,
            0
        );

        emit RatioForFundingSet(
            0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986,
            AllRatioForFundingParam(750, 2000, 7000, 250, 3500, 6000, 800, 2000, 7000, 800, 2000, 7000)
        );

        emit InitialTokenSupplyForSubDaoSet(0xe9f6527f34fb69a20cfc91e2d1a3f3ad3671c7e6bdf38b3af98f4dd528e96986, 1e28);

        emit DaoMintableRoundSet(0x33b72e7b377e4c63b14642b1ca3ca3b2d8a32129459d1cf393e765895e51f649, 60);

        emit DaoNftMaxSupplySet(0x33b72e7b377e4c63b14642b1ca3ca3b2d8a32129459d1cf393e765895e51f649, 1000);

        emit DailyMintCapSet(0x33b72e7b377e4c63b14642b1ca3ca3b2d8a32129459d1cf393e765895e51f649, 100);

        emit DaoFloorPriceSet(
            0x33b72e7b377e4c63b14642b1ca3ca3b2d8a32129459d1cf393e765895e51f649, 30_000_000_000_000_000
        );

        emit DaoUnifiedPriceSet(0x33b72e7b377e4c63b14642b1ca3ca3b2d8a32129459d1cf393e765895e51f649, 1006);

        emit DaoPriceTemplateSet(
            0x33b72e7b377e4c63b14642b1ca3ca3b2d8a32129459d1cf393e765895e51f649,
            PriceTemplateType.LINEAR_PRICE_VARIATION,
            1000
        );
        //mint event

        emit MintFeeSplitted(
            0x0df7b9ea23842bc49ba7f944c706d2a15230b682963e154eaec6152608dd8393,
            0xc9c8a2A73d591B1411Acbbf5423CCEEdF36F8e97,
            6_000_000_000_000_000,
            0xfde7a05310B5c14E628f11C15a8Cad6fcBd1C398,
            250_000_000_000_000,
            0x1b6cF3C12Fc589E98BD60857577F73C37ce6186f,
            350_000_000_000_000
        );

        emit D4AMintNFT(
            0x0df7b9ea23842bc49ba7f944c706d2a15230b682963e154eaec6152608dd8393,
            0xc6b344799718aec19d11a2e79c92e2843d897c56f1cd1cfed5f77dd1d18b5d65,
            1,
            "https://dao4art.s3.ap-southeast-1.amazonaws.com/meta/work/110-0.json",
            10_000_000_000_000_000
        );

        // claim event
        emit PDClaimCanvasReward(
            0x0df7b9ea23842bc49ba7f944c706d2a15230b682963e154eaec6152608dd8393,
            0xc6b344799718aec19d11a2e79c92e2843d897c56f1cd1cfed5f77dd1d18b5d65,
            0xe6342d41b9Fa0b899705354EFfC45736079C7131,
            0,
            0
        );
        emit PDClaimDaoCreatorReward(
            0x0df7b9ea23842bc49ba7f944c706d2a15230b682963e154eaec6152608dd8393,
            0xe6342d41b9Fa0b899705354EFfC45736079C7131,
            0,
            0
        );
        emit PDClaimNftMinterReward(
            0x0df7b9ea23842bc49ba7f944c706d2a15230b682963e154eaec6152608dd8393,
            0xe6342d41b9Fa0b899705354EFfC45736079C7131,
            0,
            0
        );
        //Top up event
        emit TopUpAmountUsed(
            0xc4A85539c14fC83C3413666588C6E42202f9DD8e,
            0x0123ea2bc30b8ab134d684f21685f0cce920385229fcb2d35b224d9987baa0a8,
            0xc9c8a2A73d591B1411Acbbf5423CCEEdF36F8e97,
            833_333_333_333_333_333_333_333,
            10_000_000_000_000_000
        );

        emit PDClaimNftMinterRewardTopUp(
            0x0123ea2bc30b8ab134d684f21685f0cce920385229fcb2d35b224d9987baa0a8,
            0xe6342d41b9Fa0b899705354EFfC45736079C7131,
            833_333_333_333_333_333_333_333,
            10_000_000_000_000_000
        );
        //distrbution event
        emit DaoBlockRewardDistributedToChildrenDao(
            0xdde324e1ebe574cb868a40df31b612143d162b2c11067aac23b6b4b8046abc8e,
            0xa29360863d666a79e600ae6c67ec090874b8eb656bf595009c35fd7e33252ec8,
            0x0000000000000000000000000000000000000000,
            0,
            1
        );

        emit DaoBlockRewardDistributedToRedeemPool(
            0xdde324e1ebe574cb868a40df31b612143d162b2c11067aac23b6b4b8046abc8e,
            0xc9c8a2A73d591B1411Acbbf5423CCEEdF36F8e97,
            0x0000000000000000000000000000000000000000,
            0,
            1
        );

        emit DaoBlockRewardForSelf(
            0xdde324e1ebe574cb868a40df31b612143d162b2c11067aac23b6b4b8046abc8e,
            0x0000000000000000000000000000000000000000,
            0,
            1
        );
    }
}
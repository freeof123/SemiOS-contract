// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/interface/D4AStructs.sol";
import "contracts/interface/D4AEnums.sol";

contract EventEmitter {
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

    constructor() {
        address[] memory zeroAddressArray = new address[](0);
        bytes32[] memory zeroBytes32Array = new bytes32[](0);
        uint256[] memory zeroUintArray = new uint256[](0);

        UserMintCapParam[] memory userMintCapParam = new UserMintCapParam[](1);
        userMintCapParam[0] = UserMintCapParam(0xfde7a05310B5c14E628f11C15a8Cad6fcBd1C398, 5);
        NftMinterCapInfo[] memory nftMinterCapInfo = new NftMinterCapInfo[](1);
        nftMinterCapInfo[0] = NftMinterCapInfo(0x0000000000000000000000000000000000000000, 5);

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
    }
}
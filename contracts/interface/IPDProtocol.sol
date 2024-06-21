// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { MintNftInfo, CreateCanvasAndMintNFTParam, MintNFTParam, NftIdentifier } from "./D4AStructs.sol";

interface IPDProtocol {
    event D4AMintNFT(
        bytes32 daoId, bytes32 canvasId, uint256 tokenId, string tokenUri, uint256 price, NftIdentifier ownerNft
    );

    event PDClaimDaoCreatorReward(
        bytes32 daoId, address token, uint256 outputAmount, uint256 inputAmount, address receiver
    );

    event PDClaimCanvasReward(
        bytes32 daoId, bytes32 canvasId, address token, uint256 outputAmount, uint256 inputAmount, address receiver
    );

    event PDClaimNftMinterReward(
        bytes32 daoId, address token, uint256 outputAmount, uint256 inputAmount, address receiver
    );

    event D4AExchangeOutputToInput(bytes32 daoId, address owner, address to, uint256 tokenAmount, uint256 inputAmount);

    event TopUpAmountUsed(
        NftIdentifier nft, bytes32 daoId, address redeemPool, uint256 outputAmount, uint256 inputAmount
    );

    event MintFeeSplitted(
        bytes32 daoId,
        address daoRedeemPool,
        uint256 redeemPoolFee,
        address canvasOwner,
        uint256 canvasCreatorFee,
        address daoAssetPool,
        uint256 assetPoolFee
    );

    event MintFeePendingToNftTopUpAccount(bytes32 daoId, NftIdentifier nft, uint256 feePendingToTopUpAccount);

    event NewCanvasForMint(bytes32 daoId, bytes32 canvasId, string canvasUri);

    event TopUpOutputSplitted(
        bytes32 daoId,
        address msgSender,
        address treasuryAddress,
        uint256 topUpOutputAmountToSender,
        uint256 topUpOutputAmountToTreasury
    );
    event TopUpInputSplitted(
        bytes32 daoId,
        address msgSender,
        address redeemPool,
        uint256 topUpInputAmountToSender,
        uint256 topUpInputAmountToRedeemPool
    );

    function initialize() external;

    function mintNFT(CreateCanvasAndMintNFTParam calldata vars) external payable returns (uint256);

    function exchangeOutputToInput(bytes32 daoId, uint256 amount, address to) external returns (uint256);

    function claimDaoNftOwnerReward(bytes32 daoId)
        external
        returns (uint256 daoNftOwnerOutputReward, uint256 daoNftOwnerInputReward);

    function claimCanvasReward(bytes32 canvasId)
        external
        returns (uint256 canvasCreatorOutputReward, uint256 canvasCreatorInputReward);
    function claimNftMinterReward(
        bytes32 daoId,
        address minter
    )
        external
        returns (uint256 nftMinterOutputReward, uint256 nftMinterInputReward);
}

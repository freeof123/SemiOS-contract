// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { MintNftInfo, CreateCanvasAndMintNFTParam, MintNFTParam, NftIdentifier } from "./D4AStructs.sol";

interface IPDProtocol {
    event D4AMintNFT(bytes32 daoId, bytes32 canvasId, uint256 tokenId, string tokenUri, uint256 price);

    // event D4AClaimProjectERC20Reward(bytes32 daoId, address token, uint256 amount);

    // event D4AClaimCanvasReward(bytes32 daoId, bytes32 canvasId, address token, uint256 amount);

    // event D4AClaimNftMinterReward(bytes32 daoId, address token, uint256 amount);

    event PDClaimDaoCreatorReward(bytes32 daoId, address token, uint256 erc20Amount, uint256 ethAmount);

    event PDClaimCanvasReward(bytes32 daoId, bytes32 canvasId, address token, uint256 erc20Amount, uint256 ethAmount);

    event PDClaimNftMinterReward(bytes32 daoId, address token, uint256 erc20Amount, uint256 ethAmount);

    event PDClaimNftTopUpBalance(
        bytes32 daoId, address token, NftIdentifier nft, uint256 erc20Amount, uint256 ethAmount
    );

    event D4AExchangeERC20ToERC20(
        bytes32 daoId, address owner, address to, address grantToken, uint256 tokenAmount, uint256 grantTokenAmount
    );

    event D4AExchangeERC20ToETH(bytes32 daoId, address owner, address to, uint256 tokenAmount, uint256 ethAmount);

    event TopUpAmountUsed(NftIdentifier nft, bytes32 daoId, address redeemPool, uint256 erc20Amount, uint256 ethAmount);

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

    function initialize() external;

    // function createCanvasAndMintNFT(CreateCanvasAndMintNFTParam calldata createCanvasAndMintNFTParam)
    //     external
    //     payable
    //     returns (uint256);

    // function mintNFT(
    //     bytes32 daoId,
    //     bytes32 canvasId,
    //     string calldata tokenUri,
    //     bytes32[] calldata proof,
    //     uint256 nftFlatPrice,
    //     bytes calldata nftSignature,
    //     bytes calldata erc20Signature,
    //     uint256 deadline
    // )
    //     external
    //     payable
    //     returns (uint256);

    function mintNFT(CreateCanvasAndMintNFTParam calldata vars) external payable returns (uint256);

    function exchangeERC20ToETH(bytes32 daoId, uint256 amount, address to) external returns (uint256);

    function claimDaoCreatorReward(bytes32 daoId)
        external
        returns (uint256 daoCreatorERC20Reward, uint256 daoCreatorETHReward);

    function claimCanvasReward(bytes32 canvasId)
        external
        returns (uint256 canvasCreatorERC20Reward, uint256 canvasCreatorETHReward);
    function claimNftMinterReward(
        bytes32 daoId,
        address minter
    )
        external
        returns (uint256 nftMinterERC20Reward, uint256 nftMinterETHReward);

    function updateTopUpAccount(
        bytes32 daoId,
        NftIdentifier memory nft
    )
        external
        returns (uint256 topUPERC20Quota, uint256 topUpETHQuota);
}

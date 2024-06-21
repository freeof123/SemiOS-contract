// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPDGrant {
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

    event NewSemiOsGrantTreasuryNft(
        address erc721Address,
        uint256 tokenId,
        bytes32 daoId,
        address granter,
        uint256 grantAmount,
        uint256 grantBlock,
        address token
    );

    function grantDaoAssetPool(
        bytes32 daoId,
        uint256 amount,
        bool useTreasury,
        string calldata tokenUri,
        address token
    )
        external;

    function grantDaoAssetPoolWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        address token,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
    function grantTreasury(bytes32 daoId, uint256 amount, string calldata tokenUri, address token) external;
    function grantTreasuryWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        address token,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
}

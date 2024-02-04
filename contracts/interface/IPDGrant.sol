// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPDGrant {
    error TokenNotAllowed(address token);

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

    function addAllowedToken(address token) external;

    function removeAllowedToken(address token) external;

    function grantETH(bytes32 daoId) external payable;

    function grant(bytes32 daoId, address token, uint256 amount) external;

    function grantWithPermit(
        bytes32 daoId,
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function getVestingWallet(bytes32 daoId) external view returns (address);

    function getAllowedTokensList() external view returns (address[] memory);

    function isTokenAllowed(address token) external view returns (bool);

    function grantDaoAssetPool(bytes32 daoId, uint256 amount, bool useTreasury, string calldata tokenUri) external;

    function grantDaoAssetPoolWithPermit(
        bytes32 daoId,
        uint256 amount,
        string calldata tokenUri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
}

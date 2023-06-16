// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC721URIStorageUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { ERC721RoyaltyUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import { DefaultOperatorFiltererUpgradeable } from
    "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract NftCollectionUpgradeable is
    AccessControlUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    uint256 internal _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTY_SETTER_ROLE = keccak256("ROYALTY_SETTER_ROLE");

    string public contractUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setContractUri(string memory newContractUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractUri = newContractUri;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string calldata contractUri_,
        address admin,
        address minter,
        address royaltySetter
    )
        public
        initializer
    {
        __AccessControl_init();

        __ERC721_init(name, symbol);
        contractUri = contractUri_;
        __ERC721URIStorage_init();
        __ERC721Royalty_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(ROYALTY_SETTER_ROLE, royaltySetter);
        __DefaultOperatorFilterer_init();
    }

    function mintItem(address player, string memory uri) public onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIds += 1;
        uint256 newItemId = _tokenIds;
        _mint(player, newItemId);
        _setTokenURI(newItemId, uri);
        return newItemId;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) public onlyRole(ROYALTY_SETTER_ROLE) {
        _setDefaultRoyalty(_receiver, _royaltyFeeInBips);
    }

    function _burn(uint256 _tokenId) internal override(ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable) {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function changeAdmin(address new_admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != new_admin, "new admin cannot be same as old one");
        _grantRole(DEFAULT_ADMIN_ROLE, new_admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721RoyaltyUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

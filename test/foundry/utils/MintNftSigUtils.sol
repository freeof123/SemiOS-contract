// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MintNftSigUtils {
    bytes32 private _HASHED_NAME = keccak256(bytes("ProtoDaoProtocol"));
    bytes32 private _HASHED_VERSION = keccak256(bytes("1"));

    bytes32 private _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    constructor(address verifyingContract) {
        DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, verifyingContract);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4(address verifyingContract) internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), verifyingContract);
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash,
        address verifyingContract
    )
        private
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, verifyingContract));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        return _HASHED_VERSION;
    }

    function getStructHash(
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(MINTNFT_TYPEHASH, canvasId, keccak256(bytes(tokenUri)), flatPrice));
    }

    function getTypedDataHash(
        bytes32 canvasId,
        string memory tokenUri,
        uint256 flatPrice
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(canvasId, tokenUri, flatPrice)));
    }
}

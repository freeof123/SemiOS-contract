// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PermissionControl} from "contracts/permission-control/PermissionControl.sol";

import "forge-std/Test.sol";

contract PermissionControlSigUtils {
    bytes32 private _HASHED_NAME = keccak256(bytes("D4APermissionControl"));
    bytes32 private _HASHED_VERSION = keccak256(bytes("1"));

    bytes32 private _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 internal constant _ADDPERMISSION_TYPEHASH = keccak256(
        abi.encodePacked(
            abi.encodePacked("AddPermission(bytes32 daoId,Whitelist whitelist,Blacklist blacklist)"),
            abi.encodePacked("Blacklist(address[] minterAccounts,address[] canvasCreatorAccounts)"),
            abi.encodePacked(
                "Whitelist(",
                "bytes32 minterMerkleRoot,",
                "address[] minterNFTHolderPasses,",
                "bytes32 canvasCreatorMerkleRoot,",
                "address[] canvasCreatorNFTHolderPasses",
                ")"
            )
        )
    );
    bytes32 internal constant _BLACKLIST_TYPEHASH = keccak256(
        abi.encodePacked(abi.encodePacked("Blacklist(address[] minterAccounts,address[] canvasCreatorAccounts)"))
    );
    bytes32 internal constant _WHITELIST_TYPEHASH = keccak256(
        abi.encodePacked(
            abi.encodePacked(
                "Whitelist(",
                "bytes32 minterMerkleRoot,",
                "address[] minterNFTHolderPasses,",
                "bytes32 canvasCreatorMerkleRoot,",
                "address[] canvasCreatorNFTHolderPasses",
                ")"
            )
        )
    );

    constructor(address verifyingContract) {
        DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, verifyingContract);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4(address verifyingContract) internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), verifyingContract);
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash, bytes32 versionHash, address verifyingContract)
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
        bytes32 daoId,
        PermissionControl.Whitelist memory whitelist,
        PermissionControl.Blacklist memory blacklist
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _ADDPERMISSION_TYPEHASH,
                daoId,
                // struct values are encoded recursively as hashStruct(value)
                keccak256(
                    abi.encode(
                        _WHITELIST_TYPEHASH,
                        whitelist.minterMerkleRoot,
                        keccak256(abi.encodePacked(whitelist.minterNFTHolderPasses)),
                        whitelist.canvasCreatorMerkleRoot,
                        keccak256(abi.encodePacked(whitelist.canvasCreatorNFTHolderPasses))
                    )
                ),
                keccak256(
                    abi.encode(
                        _BLACKLIST_TYPEHASH,
                        // array values are encoded as the keccak256 hash
                        // of the concatenated encodeData of their contents
                        keccak256(abi.encodePacked(blacklist.minterAccounts)),
                        keccak256(abi.encodePacked(blacklist.canvasCreatorAccounts))
                    )
                )
            )
        );
    }

    function getTypedDataHash(
        bytes32 daoId,
        PermissionControl.Whitelist memory whitelist,
        PermissionControl.Blacklist memory blacklist
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(daoId, whitelist, blacklist)));
    }
}

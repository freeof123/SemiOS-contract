// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { DaoMintInfo } from "contracts/interface/D4AStructs.sol";

import { D4AProtocol } from "contracts/D4AProtocol.sol";

contract D4AProtocolHarness is D4AProtocol {
    function exposed_MINTNFT_TYPEHASH() public pure returns (bytes32) {
        return MINTNFT_TYPEHASH;
    }

    function exposed_daoMintInfos(bytes32 daoId) public view returns (uint32 daoMintCap) {
        return _daoMintInfos[daoId].daoMintCap;
    }

    function exposed_checkMintEligibility(
        bytes32 daoId,
        address account,
        bytes32[] calldata proof,
        uint256 amount
    )
        public
        view
    {
        _checkMintEligibility(daoId, account, proof, amount);
    }

    function exposed_ableToMint(
        bytes32 daoId,
        address account,
        bytes32[] calldata proof,
        uint256 amount
    )
        public
        view
        returns (bool)
    {
        return _ableToMint(daoId, account, proof, amount);
    }

    function exposed_verifySignature(
        bytes32 canvasId,
        string calldata tokenUri,
        uint256 flatPrice,
        bytes calldata signature
    )
        public
        view
    {
        _verifySignature(canvasId, tokenUri, flatPrice, signature);
    }
}

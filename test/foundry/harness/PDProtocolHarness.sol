// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { PDProtocol } from "contracts/PDProtocol.sol";

contract PDProtocolHarness is PDProtocol {
    function exposed_isSpecialTokenUri(bytes32 daoId, string calldata tokenUri) public view returns (bool) {
        return _isSpecialTokenUri(daoId, tokenUri);
    }
}

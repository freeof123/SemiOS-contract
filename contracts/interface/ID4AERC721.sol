// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721 {
    function mintItem(
        address player,
        string memory tokenURI,
        uint256 tokenId,
        bool zeroTokenId
    )
        external
        returns (uint256);

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips) external;
    function setContractUri(string memory _uri) external;
}

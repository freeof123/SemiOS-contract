// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DaoMetadataParam, BasicDaoParam } from "contracts/interface/D4AStructs.sol";

interface ID4ACreate {
    event NewProject(
        bytes32 daoId, string daoUri, address daoFeePool, address token, address nft, uint256 royaltyFeeRatioInBps
    );

    event NewCanvas(bytes32 daoId, bytes32 canvasId, string canvasUri);

    function createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        string calldata daoUri
    )
        external
        payable
        returns (bytes32 daoId);

    function createOwnerProject(DaoMetadataParam calldata daoMetadataParam) external payable returns (bytes32 daoId);

    function createCanvas(
        bytes32 daoId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        uint256 canvasRebateRatioInBps
    )
        external
        payable
        returns (bytes32);
}

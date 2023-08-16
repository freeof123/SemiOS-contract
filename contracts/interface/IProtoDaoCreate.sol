// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DaoMetadataParam, BasicDaoParam } from "contracts/interface/D4AStructs.sol";

interface IProtoDaoCreate {
    event NewProject(
        bytes32 daoId, string daoUri, address daoFeePool, address token, address nft, uint256 royaltyFeeRatioInBps
    );

    event NewCanvas(bytes32 daoId, bytes32 canvasId, string canvasUri);

    function createBasicDao(
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam
    )
        external
        payable
        returns (bytes32 daoId);

    function createCanvas(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        uint256 canvasRebateRatioInBps,
        address to
    )
        external
        payable;
}

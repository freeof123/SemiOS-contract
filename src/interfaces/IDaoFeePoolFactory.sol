// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDaoFeePoolFactory {
    function createDaoFeePool(
        uint256 daoIndex,
        address admin,
        address autoTransferer
    )
        external
        returns (address daoFeePool);
}

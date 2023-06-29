// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { PriceTemplateType, RewardTemplateType } from "../interface/D4AEnums.sol";
import { DaoStorage } from "../storages/DaoStorage.sol";
import { PriceStorage } from "../storages/PriceStorage.sol";
import { RewardStorage } from "../storages/RewardStorage.sol";
import { SettingsStorage } from "../storages/SettingsStorage.sol";
import { ID4AChangeAdmin } from "../interface/ID4AChangeAdmin.sol";
import { ID4ADrb } from "../interface/ID4ADrb.sol";
import "../D4AERC721.sol";
import "../feepool/D4AFeePool.sol";
import "../D4AERC20.sol";

library D4AProject {
    using StringsUpgradeable for uint256;

    error D4AInsufficientEther(uint256 required);
    error D4AProjectAlreadyExist(bytes32 project_id);

    event NewProject(
        bytes32 project_id, string uri, address fee_pool, address erc20_token, address erc721_token, uint256 royalty_fee
    );

    function createProject(
        mapping(bytes32 => DaoStorage.DaoInfo) storage daoInfos,
        uint256 _start_prb,
        uint256 _mintable_rounds,
        uint256 _floor_price_rank,
        uint256 _max_nft_rank,
        uint96 _royalty_fee,
        uint256 _project_index,
        string memory _project_uri
    )
        public
        returns (bytes32 project_id)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        require(l.project_max_rounds >= _mintable_rounds, "rounds too long, not support");
        {
            uint256 protocol_fee = l.mint_d4a_fee_ratio;
            require(
                _royalty_fee >= l.rf_lower_bound + protocol_fee && _royalty_fee <= l.rf_upper_bound + protocol_fee,
                "royalty fee out of range"
            );
        }
        {
            uint256 minimal = l.create_project_fee;
            require(msg.value >= minimal, "not enough ether to create project");

            SafeTransferLib.safeTransferETH(l.protocolFeePool, minimal);
            uint256 exchange = msg.value - minimal;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }

        project_id = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = daoInfos[project_id];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(project_id);
        {
            daoInfo.startRound = _start_prb;
            {
                ID4ADrb drb = l.drb;
                uint256 cur_round = drb.currentRound();
                require(_start_prb >= cur_round, "start round already passed");
            }
            daoInfo.mintableRound = _mintable_rounds;
            daoInfo.nftMaxSupply = l.max_nft_amounts[_max_nft_rank];
            daoInfo.daoUri = _project_uri;
            daoInfo.royaltyFeeInBps = _royalty_fee;
            daoInfo.daoIndex = _project_index;
            daoInfo.token = _createERC20Token(_project_index);

            D4AERC20(daoInfo.token).grantRole(keccak256("MINTER"), address(this));
            D4AERC20(daoInfo.token).grantRole(keccak256("BURNER"), address(this));

            address pool = l.feepool_factory.createD4AFeePool(
                string(abi.encodePacked("Asset Pool for DAO4Art Project ", _project_index.toString()))
            );

            D4AFeePool(payable(pool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

            ID4AChangeAdmin(pool).changeAdmin(l.asset_pool_owner);
            ID4AChangeAdmin(daoInfo.token).changeAdmin(l.asset_pool_owner);

            daoInfo.daoFeePool = pool;

            l.owner_proxy.initOwnerOf(project_id, msg.sender);

            daoInfo.nft = _createERC721Token(_project_index);
            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), msg.sender);
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(_project_uri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(l.asset_pool_owner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender);
            //We copy from setting in case setting may change later.
            daoInfo.tokenMaxSupply = l.erc20_total_supply;

            if (_floor_price_rank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[project_id] = l.floor_prices[_floor_price_rank];
            }
            RewardStorage.layout().rewardInfos[project_id].totalReward = l.erc20_total_supply;
            // TODO: remove this to save gas? because impossible to mint NFT at round 0, or change prb such that it
            // starts at round 1
            RewardStorage.layout().rewardInfos[project_id].rewardPendingRound = type(uint256).max;

            daoInfo.daoExist = true;
            emit NewProject(project_id, _project_uri, pool, daoInfo.token, daoInfo.nft, _royalty_fee);
        }
    }

    /*function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);

    }

    function toHex (bytes32 data) internal pure returns (string memory) {
    return string (abi.encodePacked (toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
    }
    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
          result[i-startIndex] = strBytes[i];
    }
    return string(result);
    }*/

    function _createERC20Token(uint256 _project_num) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = string(abi.encodePacked("D4A Token for No.", _project_num.toString()));
        string memory sym = string(abi.encodePacked("D4A.T", _project_num.toString()));
        return l.erc20_factory.createD4AERC20(name, sym, address(this));
    }

    function _createERC721Token(uint256 _project_num) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = string(abi.encodePacked("D4A NFT for No.", _project_num.toString()));
        string memory sym = string(abi.encodePacked("D4A.N", _project_num.toString()));
        return l.erc721_factory.createD4AERC721(name, sym);
    }
}

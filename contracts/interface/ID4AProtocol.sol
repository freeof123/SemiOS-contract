// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import { DaoMetadataParam, UserMintCapParam, TemplateParam } from "contracts/interface/D4AStructs.sol";

import "../libraries/D4AProject.sol";
import "../libraries/D4ACanvas.sol";
import "../libraries/D4APrice.sol";
import "../libraries/D4AReward.sol";
import { PriceStorage } from "../storages/PriceStorage.sol";
import { IPriceTemplate } from "../interface/IPriceTemplate.sol";

abstract contract ID4AProtocol {
    using D4AProject for mapping(bytes32 => D4AProject.project_info);
    using D4ACanvas for mapping(bytes32 => D4ACanvas.canvas_info);

    // TODO: add getters for all the mappings
    mapping(bytes32 => D4AProject.project_info) internal _allProjects;
    mapping(bytes32 => D4ACanvas.canvas_info) internal _allCanvases;
    mapping(bytes32 => bytes32) public tokenid_2_canvas;

    address private __DEPRECATED_SETTINGS;

    function createProject(
        uint256 _start_prb,
        uint256 _mintable_rounds,
        uint256 _floor_price_rank,
        uint256 _max_nft_rank,
        uint96 _royalty_fee,
        string memory _project_uri
    )
        external
        payable
        virtual
        returns (bytes32 project_id);

    function createOwnerProject(DaoMetadataParam calldata daoMetadata)
        external
        payable
        virtual
        returns (bytes32 project_id);

    function getProjectCanvasAt(bytes32 _project_id, uint256 _index) public view returns (bytes32) {
        return _allProjects.getProjectCanvasAt(_project_id, _index);
    }

    function getProjectInfo(bytes32 _project_id)
        public
        view
        returns (
            uint256 start_prb,
            uint256 mintable_rounds,
            uint256 max_nft_amount,
            address fee_pool,
            uint96 royalty_fee,
            uint256 index,
            string memory uri,
            uint256 erc20_total_supply
        )
    {
        return _allProjects.getProjectInfo(_project_id);
    }

    function getProjectFloorPrice(bytes32 _project_id) public view returns (uint256) {
        return PriceStorage.layout().daoFloorPrices[_project_id];
    }

    function getProjectTokens(bytes32 _project_id) public view returns (address erc20_token, address erc721_token) {
        erc20_token = _allProjects[_project_id].erc20_token;
        erc721_token = _allProjects[_project_id].erc721_token;
    }

    function getCanvasNFTCount(bytes32 _canvas_id) public view returns (uint256) {
        return _allCanvases.getCanvasNFTCount(_canvas_id);
    }

    function getTokenIDAt(bytes32 _canvas_id, uint256 _index) public view returns (uint256) {
        return _allCanvases.getTokenIDAt(_canvas_id, _index);
    }

    function getCanvasProject(bytes32 _canvas_id) public view returns (bytes32) {
        return _allCanvases[_canvas_id].project_id;
    }

    function getCanvasIndex(bytes32 _canvas_id) public view returns (uint256) {
        return _allCanvases[_canvas_id].index;
    }

    function getCanvasURI(bytes32 _canvas_id) public view returns (string memory) {
        return _allCanvases.getCanvasURI(_canvas_id);
    }

    function getCanvasLastPrice(bytes32 canvasId) public view returns (uint256 round, uint256 price) {
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().lastMintInfos[canvasId];
        return (mintInfo.round, mintInfo.price);
    }

    function getCanvasNextPrice(bytes32 canvasId) public view returns (uint256) {
        bytes32 daoId = _allCanvases[canvasId].project_id;
        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        return IPriceTemplate(_allProjects[daoId].priceTemplate).getCanvasNextPrice(
            daoId, canvasId, pi.start_prb, l.drb.currentRound(), pi.nftPriceFactor
        );
    }

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        IPermissionControl.Whitelist memory whitelist,
        IPermissionControl.Blacklist memory blacklist,
        IPermissionControl.Blacklist memory unblacklist
    )
        external
        virtual;

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import { NotDaoOwner, InvalidERC20Ratio, InvalidERC20Ratio, InvalidETHRatio } from "contracts/interface/D4AErrors.sol";
import { DaoMetadataParam, TemplateParam, UpdateRewardParam } from "contracts/interface/D4AStructs.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { D4ASettingsBaseStorage } from "./D4ASettings/D4ASettingsBaseStorage.sol";
import { D4AProject } from "./libraries/D4AProject.sol";
import { D4ACanvas } from "./libraries/D4ACanvas.sol";
import { ID4AProtocol } from "./interface/ID4AProtocol.sol";
import { ID4AERC721 } from "./interface/ID4AERC721.sol";
import { IPriceTemplate } from "./interface/IPriceTemplate.sol";
import { IRewardTemplate } from "./interface/IRewardTemplate.sol";
import { D4AERC20 } from "./D4AERC20.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";

abstract contract D4AProtocol is Initializable, ReentrancyGuardUpgradeable, ID4AProtocol {
    struct MintNftInfo {
        string tokenUri;
        uint256 flatPrice;
    }

    struct MintVars {
        uint32 length;
        uint256 currentRound;
        uint256 nftPriceFactor;
        uint256 priceChangeBasisPoint;
        uint256 price;
        uint256 daoTotalShare;
        uint256 totalPrice;
        uint256 daoFee;
        uint256 initialPrice;
    }

    struct GetCanvasNextPriceParam {
        bytes32 daoId;
        bytes32 canvasId;
        uint256 startPrb;
        uint256 currentRound;
        uint256 nftPriceFactor;
        uint256 flatPrice;
    }

    using D4AProject for mapping(bytes32 => D4AProject.project_info);
    using D4ACanvas for mapping(bytes32 => D4ACanvas.canvas_info);

    mapping(bytes32 => bool) public uri_exists;

    uint256 public project_num;

    mapping(bytes32 => mapping(uint256 => uint256)) public round_2_total_eth;

    uint256 public canvas_num;

    uint256 public project_bitmap;

    // event from library
    event NewProject(
        bytes32 project_id, string uri, address fee_pool, address erc20_token, address erc721_token, uint256 royalty_fee
    );
    event NewCanvas(bytes32 project_id, bytes32 canvas_id, string uri);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    error NotRole(bytes32 role, address account);

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert NotRole(role, account);
        }
    }

    function _hasRole(bytes32 role, address account) internal view virtual returns (bool) {
        return IAccessControlUpgradeable(address(this)).hasRole(role, account);
    }

    function changeProjectNum(uint256 _project_num) public onlyRole(bytes32(0)) {
        project_num = _project_num;
    }

    error NotCaller(address caller);

    modifier onlyCaller(address caller) {
        _checkCaller(caller);
        _;
    }

    function _checkCaller(address caller) internal view {
        if (caller != msg.sender) {
            revert NotCaller(caller);
        }
    }

    modifier d4aNotPaused() {
        _checkPauseStatus();
        _;
    }

    error D4APaused();

    function _checkPauseStatus() internal view {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (l.d4a_pause) {
            revert D4APaused();
        }
    }

    modifier notPaused(bytes32 id) {
        _checkPauseStatus(id);
        _;
    }

    error Paused(bytes32 id);

    function _checkPauseStatus(bytes32 id) internal view {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (l.pause_status[id]) {
            revert Paused(id);
        }
    }

    error UriAlreadyExist(string uri);

    error UriNotExist(string uri);

    modifier uriExist(string calldata uri) {
        _checkUriExist(uri);
        _;
    }

    modifier uriNotExist(string calldata uri) {
        _checkUriNotExist(uri);
        _;
    }

    function _uriExist(string calldata uri) internal view returns (bool) {
        return uri_exists[keccak256(abi.encodePacked(uri))];
    }

    function _checkUriExist(string calldata uri) internal view {
        if (!_uriExist(uri)) {
            revert UriNotExist(uri);
        }
    }

    function _checkUriNotExist(string calldata uri) internal view {
        if (_uriExist(uri)) {
            revert UriAlreadyExist(uri);
        }
    }

    function createProject(
        uint256 _start_prb,
        uint256 _mintable_rounds,
        uint256 _floor_price_rank,
        uint256 _max_nft_rank,
        uint96 _royalty_fee,
        string calldata _project_uri
    )
        public
        payable
        override
        nonReentrant
        d4aNotPaused
        uriNotExist(_project_uri)
        returns (bytes32 project_id)
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        _checkCaller(l.project_proxy);
        uri_exists[keccak256(abi.encodePacked(_project_uri))] = true;
        project_id = _allProjects.createProject(
            _start_prb, _mintable_rounds, _floor_price_rank, _max_nft_rank, _royalty_fee, project_num, _project_uri
        );
        project_num++;
    }

    error DaoIndexTooLarge();
    error DaoIndexAlreadyExist();

    function createOwnerProject(DaoMetadataParam calldata daoMetadataParam)
        public
        payable
        override
        nonReentrant
        d4aNotPaused
        returns (
            // uriNotExist(_project_uri)
            bytes32 project_id
        )
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        _checkCaller(l.project_proxy);
        {
            _checkUriNotExist(daoMetadataParam.projectUri);
        }
        {
            if (daoMetadataParam.projectIndex >= l.reserved_slots) revert DaoIndexTooLarge();
            if (((project_bitmap >> daoMetadataParam.projectIndex) & 1) != 0) revert DaoIndexAlreadyExist();
        }

        {
            project_bitmap |= (1 << daoMetadataParam.projectIndex);
            uri_exists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;
        }
        {
            return _allProjects.createProject(
                daoMetadataParam.startDrb,
                daoMetadataParam.mintableRounds,
                daoMetadataParam.floorPriceRank,
                daoMetadataParam.maxNftRank,
                daoMetadataParam.royaltyFee,
                daoMetadataParam.projectIndex,
                daoMetadataParam.projectUri
            );
        }
    }

    function getProjectCanvasCount(bytes32 _project_id) public view returns (uint256) {
        return _allProjects.getProjectCanvasCount(_project_id);
    }

    error DaoNotExist();
    error CanvasNotExist();

    modifier daoExist(bytes32 daoId) {
        _checkDaoExist(daoId);
        _;
    }

    function _checkDaoExist(bytes32 daoId) internal view {
        if (!_allProjects[daoId].exist) revert DaoNotExist();
    }

    modifier canvasExist(bytes32 canvasId) {
        _checkCanvasExist(canvasId);
        _;
    }

    function _checkCanvasExist(bytes32 canvasId) internal view {
        if (!_allCanvases[canvasId].exist) revert CanvasNotExist();
    }

    function _createCanvas(
        bytes32 _project_id,
        string calldata _canvas_uri
    )
        internal
        d4aNotPaused
        daoExist(_project_id)
        notPaused(_project_id)
        uriNotExist(_canvas_uri)
        returns (bytes32 canvas_id)
    {
        uri_exists[keccak256(abi.encodePacked(_canvas_uri))] = true;

        canvas_id = _allCanvases.createCanvas(
            _allProjects[_project_id].fee_pool,
            _project_id,
            _allProjects[_project_id].start_prb,
            _allProjects.getProjectCanvasCount(_project_id),
            _canvas_uri
        );

        _allProjects[_project_id].canvases.push(canvas_id);
    }

    event D4AMintNFT(bytes32 project_id, bytes32 canvas_id, uint256 token_id, string token_uri, uint256 price);

    error NftExceedMaxAmount();

    error PriceTooLow();

    function _mintNft(
        bytes32 canvasId,
        string calldata _token_uri,
        uint256 flatPrice
    )
        internal
        returns (
            // d4aNotPaused
            // notPaused(canvasId)
            // canvasExist(canvasId)
            // uriNotExist(_token_uri)
            uint256 token_id
        )
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        {
            _checkPauseStatus();
            _checkPauseStatus(canvasId);
            _checkCanvasExist(canvasId);
            _checkUriNotExist(_token_uri);
        }
        bytes32 daoId = _allCanvases[canvasId].project_id;

        if (flatPrice != 0 && flatPrice < getProjectFloorPrice(daoId)) revert PriceTooLow();
        _checkPauseStatus(daoId);

        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ACanvas.canvas_info storage ci = _allCanvases[canvasId];
        if (pi.nft_supply >= pi.max_nft_amount) revert NftExceedMaxAmount();

        MintVars memory vars;
        vars.currentRound = l.drb.currentRound();
        vars.nftPriceFactor = pi.nftPriceFactor;

        {
            bytes32 token_uri_hash = keccak256(abi.encodePacked(_token_uri));
            uri_exists[token_uri_hash] = true;
        }

        // get next mint price
        uint256 price;
        {
            uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
            PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
            PriceStorage.MintInfo memory mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
            price = _getCanvasNextPrice(
                daoId,
                flatPrice,
                pi.start_prb,
                vars.currentRound,
                vars.nftPriceFactor,
                daoFloorPrice,
                maxPrice,
                mintInfo
            );
        }

        // split fee
        {
            address protocolFeePool = l.protocolFeePool;
            address daoFeePool = pi.fee_pool;
            address canvasOwner = l.owner_proxy.ownerOf(canvasId);
            // uint256 daoShare = (flatPrice == 0 ? l.mint_project_fee_ratio : l.mint_project_fee_ratio_flat_price) *
            // price;
            uint256 daoShare =
                (flatPrice == 0 ? getDaoFeePoolETHRatio(daoId) : getDaoFeePoolETHRatioFlatPrice(daoId)) * price;

            (vars.daoFee,) =
                _splitFee(protocolFeePool, daoFeePool, canvasOwner, price, daoShare, ci.canvasRebateRatioInBps);
        }

        // update
        _updatePrice(vars.currentRound, daoId, canvasId, price, flatPrice, vars.nftPriceFactor);

        _updateReward(daoId, canvasId, vars.daoFee);

        // mint
        token_id = ID4AERC721(pi.erc721_token).mintItem(msg.sender, _token_uri);
        {
            pi.nft_supply++;
            ci.nft_tokens.push(token_id);
            ci.nft_token_number++;
            tokenid_2_canvas[keccak256(abi.encodePacked(daoId, token_id))] = canvasId;
        }

        emit D4AMintNFT(daoId, canvasId, token_id, _token_uri, price);
    }

    function _updatePrice(
        uint256 currentRound,
        bytes32 daoId,
        bytes32 canvasId,
        uint256 price,
        uint256 flatPrice,
        uint256 nftPriceMultiplyFactor
    )
        internal
    {
        if (flatPrice == 0) {
            (bool succ,) = D4ASettingsBaseStorage.layout().priceTemplates[uint8(_allProjects[daoId].priceTemplateType)]
                .delegatecall(
                abi.encodeWithSelector(
                    IPriceTemplate.updateCanvasPrice.selector,
                    daoId,
                    canvasId,
                    currentRound,
                    price,
                    nftPriceMultiplyFactor
                )
            );
            require(succ);
            // _allPrices[daoId].updateCanvasPrice(currentRound, canvasId, price, nftPriceMultiplyFactor);
        }
    }

    function _mintNft(
        bytes32 daoId,
        bytes32 canvasId,
        MintNftInfo[] calldata mintNftInfos
    )
        internal
        returns (
            // d4aNotPaused
            // notPaused(daoId)
            // canvasExist(canvasId)
            // notPaused(canvasId)
            uint256[] memory
        )
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        {
            _checkPauseStatus();
            _checkPauseStatus(daoId);
            _checkCanvasExist(canvasId);
            _checkPauseStatus(canvasId);
        }

        MintVars memory vars;
        vars.length = uint32(mintNftInfos.length);
        {
            uint256 projectFloorPrice = getProjectFloorPrice(daoId);
            for (uint32 i = 0; i < vars.length;) {
                _checkUriNotExist(mintNftInfos[i].tokenUri);
                if (mintNftInfos[i].flatPrice != 0 && mintNftInfos[i].flatPrice < projectFloorPrice) {
                    revert PriceTooLow();
                }
                unchecked {
                    ++i;
                }
            }
        }

        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ACanvas.canvas_info storage ci = _allCanvases[canvasId];
        if (pi.nft_supply + vars.length > pi.max_nft_amount) revert NftExceedMaxAmount();

        vars.currentRound = l.drb.currentRound();
        vars.nftPriceFactor = pi.nftPriceFactor;
        vars.priceChangeBasisPoint = BASIS_POINT;

        {
            uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
            PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
            PriceStorage.MintInfo memory mintInfo = PriceStorage.layout().canvasLastMintInfos[daoId];
            vars.price = _getCanvasNextPrice(
                daoId, 0, pi.start_prb, vars.currentRound, vars.nftPriceFactor, daoFloorPrice, maxPrice, mintInfo
            );
        }
        vars.initialPrice = vars.price;
        vars.daoTotalShare;
        vars.totalPrice;
        uint256[] memory tokenIds = new uint256[](vars.length);
        {
            pi.nft_supply += vars.length;
            ci.nft_token_number += vars.length;
            for (uint32 i = 0; i < vars.length;) {
                {
                    bytes32 token_uri_hash = keccak256(abi.encodePacked(mintNftInfos[i].tokenUri));
                    uri_exists[token_uri_hash] = true;
                }

                tokenIds[i] = ID4AERC721(pi.erc721_token).mintItem(msg.sender, mintNftInfos[i].tokenUri);
                {
                    ci.nft_tokens.push(tokenIds[i]);
                    tokenid_2_canvas[keccak256(abi.encodePacked(daoId, tokenIds[i]))] = canvasId;
                }
                uint256 flatPrice = mintNftInfos[i].flatPrice;
                if (flatPrice == 0) {
                    vars.daoTotalShare += l.mint_project_fee_ratio * vars.price;
                    vars.totalPrice += vars.price;
                    emit D4AMintNFT(daoId, canvasId, tokenIds[i], mintNftInfos[i].tokenUri, vars.price);
                    vars.price *= vars.nftPriceFactor / vars.priceChangeBasisPoint;
                } else {
                    vars.daoTotalShare += l.mint_project_fee_ratio_flat_price * flatPrice;
                    vars.totalPrice += flatPrice;
                    emit D4AMintNFT(daoId, canvasId, tokenIds[i], mintNftInfos[i].tokenUri, flatPrice);
                }
                unchecked {
                    ++i;
                }
            }
        }

        {
            // split fee
            address protocolFeePool = l.protocolFeePool;
            address daoFeePool = pi.fee_pool;
            address canvasOwner = l.owner_proxy.ownerOf(canvasId);

            (vars.daoFee,) = _splitFee(
                protocolFeePool, daoFeePool, canvasOwner, vars.totalPrice, vars.daoTotalShare, ci.canvasRebateRatioInBps
            );
        }

        // update canvas price
        if (vars.price != vars.initialPrice) {
            vars.price = vars.price * vars.priceChangeBasisPoint / vars.nftPriceFactor;
            _updatePrice(vars.currentRound, daoId, canvasId, vars.price, 0, vars.nftPriceFactor);
        }

        _updateReward(daoId, canvasId, vars.daoFee);

        return tokenIds;
    }

    function _getCanvasNextPrice(
        bytes32 daoId,
        uint256 flatPrice,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceFactor,
        uint256 daoFloorPrice,
        PriceStorage.MintInfo memory maxPrice,
        PriceStorage.MintInfo memory mintInfo
    )
        internal
        view
        returns (uint256 price)
    {
        if (flatPrice == 0) {
            price = IPriceTemplate(
                D4ASettingsBaseStorage.layout().priceTemplates[uint8(_allProjects[daoId].priceTemplateType)]
            ).getCanvasNextPrice(startRound, currentRound, priceFactor, daoFloorPrice, maxPrice, mintInfo);
        } else {
            price = flatPrice;
        }
    }

    function _updateReward(bytes32 daoId, bytes32 canvasId, uint256 daoFeeAmount) internal {
        D4AProject.project_info memory pi = _allProjects[daoId];
        D4ACanvas.canvas_info memory ci = _allCanvases[canvasId];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        (bool succ, bytes memory data) = D4ASettingsBaseStorage.layout().rewardTemplates[uint8(
            _allProjects[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.updateReward.selector,
                UpdateRewardParam(
                    daoId,
                    canvasId,
                    pi.start_prb,
                    l.drb.currentRound(),
                    pi.mintable_rounds,
                    daoFeeAmount,
                    l.protocolERC20RatioInBps,
                    l.daoCreatorERC20RatioInBps,
                    getCanvasCreatorERC20Ratio(canvasId),
                    getNftMinterERC20Ratio(canvasId),
                    ci.canvasRebateRatioInBps
                )
            )
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    error NotEnoughEther();

    function _splitFee(
        address protocolFeePool,
        address daoFeePool,
        address canvasOwner,
        uint256 price,
        uint256 daoShare,
        uint256 canvasRebateRatioInBps
    )
        internal
        returns (uint256 daoFee, uint256 protocolFee)
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();

        uint256 ratioBasisPoint = l.ratio_base;

        daoFee = daoShare / ratioBasisPoint;
        protocolFee = price * l.mint_d4a_fee_ratio / ratioBasisPoint;
        uint256 canvasFee = price - daoFee - protocolFee;
        uint256 rebateAmount = canvasFee * canvasRebateRatioInBps / ratioBasisPoint;
        canvasFee -= rebateAmount;
        if (msg.value < price - rebateAmount) revert NotEnoughEther();
        uint256 exchange = msg.value - price + rebateAmount;

        if (protocolFee > 0) SafeTransferLib.safeTransferETH(protocolFeePool, protocolFee);
        if (daoFee > 0) SafeTransferLib.safeTransferETH(daoFeePool, daoFee);
        if (canvasFee > 0) SafeTransferLib.safeTransferETH(canvasOwner, canvasFee);
        if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
    }

    function getNFTTokenCanvas(bytes32 _project_id, uint256 _token_id) public view returns (bytes32) {
        return tokenid_2_canvas[keccak256(abi.encodePacked(_project_id, _token_id))];
    }

    event D4AClaimProjectERC20Reward(bytes32 project_id, address erc20_token, uint256 amount);
    event D4AExchangeERC20ToETH(
        bytes32 project_id, address owner, address to, uint256 erc20_amount, uint256 eth_amount
    );

    function claimProjectERC20Reward(bytes32 daoId)
        public
        nonReentrant
        d4aNotPaused
        notPaused(daoId)
        daoExist(daoId)
        returns (uint256)
    {
        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        (bool succ, bytes memory data) = D4ASettingsBaseStorage.layout().rewardTemplates[uint8(
            _allProjects[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimDaoCreatorReward.selector,
                daoId,
                l.protocolFeePool,
                l.owner_proxy.ownerOf(daoId),
                pi.start_prb,
                l.drb.currentRound(),
                pi.mintable_rounds,
                pi.erc20_token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimProjectERC20Reward(daoId, pi.erc20_token, amount);

        return amount;
    }

    event D4AClaimCanvasReward(bytes32 project_id, bytes32 canvas_id, address erc20_token, uint256 amount);

    function claimCanvasReward(bytes32 canvasId)
        public
        nonReentrant
        d4aNotPaused
        notPaused(canvasId)
        canvasExist(canvasId)
        returns (uint256)
    {
        bytes32 daoId = _allCanvases[canvasId].project_id;
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);

        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        (bool succ, bytes memory data) = D4ASettingsBaseStorage.layout().rewardTemplates[uint8(
            _allProjects[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimCanvasCreatorReward.selector,
                daoId,
                canvasId,
                l.owner_proxy.ownerOf(canvasId),
                pi.start_prb,
                l.drb.currentRound(),
                pi.mintable_rounds,
                pi.erc20_token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimCanvasReward(daoId, canvasId, pi.erc20_token, amount);

        return amount;
    }

    event D4AClaimNftMinterReward(bytes32 daoId, address erc20Token, uint256 amount);

    function claimNftMinterReward(
        bytes32 daoId,
        address minter
    )
        public
        nonReentrant
        d4aNotPaused
        daoExist(daoId)
        notPaused(daoId)
        returns (uint256)
    {
        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        (bool succ, bytes memory data) = D4ASettingsBaseStorage.layout().rewardTemplates[uint8(
            _allProjects[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimNftMinterReward.selector,
                daoId,
                minter,
                pi.start_prb,
                l.drb.currentRound(),
                pi.mintable_rounds,
                pi.erc20_token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimNftMinterReward(daoId, pi.erc20_token, amount);

        return amount;
    }

    function exchangeERC20ToETH(
        bytes32 daoId,
        uint256 amount,
        address _to
    )
        public
        nonReentrant
        d4aNotPaused
        notPaused(daoId)
        returns (uint256)
    {
        D4AProject.project_info storage pi = _allProjects[daoId];
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        address erc20_token = pi.erc20_token;
        address fee_pool = pi.fee_pool;
        D4AERC20(erc20_token).burn(msg.sender, amount);
        D4AERC20(erc20_token).mint(fee_pool, amount);

        uint256 cur_round = l.drb.currentRound();

        uint256 circulate_erc20 =
            D4AERC20(erc20_token).totalSupply() + amount - D4AERC20(erc20_token).balanceOf(fee_pool);
        if (circulate_erc20 == 0) return 0;
        uint256 avaliable_eth = fee_pool.balance - round_2_total_eth[daoId][cur_round];
        uint256 to_send = amount * avaliable_eth / circulate_erc20;
        if (to_send != 0) {
            D4AFeePool(payable(fee_pool)).transfer(address(0x0), payable(_to), to_send);
        }
        emit D4AExchangeERC20ToETH(daoId, msg.sender, _to, amount, to_send);
        return to_send;
    }

    event DaoNftPriceMultiplyFactorChanged(bytes32 daoId, uint256 newNftPriceMultiplyFactor);

    function changeDaoNftPriceMultiplyFactor(bytes32 daoId, uint256 nftPriceFactor) public onlyRole(bytes32(0)) {
        require(nftPriceFactor >= 10_000);
        _allProjects[daoId].nftPriceFactor = nftPriceFactor;

        emit DaoNftPriceMultiplyFactorChanged(daoId, nftPriceFactor);
    }

    error NotCanvasOwner();

    event CanvasRebateRatioInBpsSet(bytes32 indexed canvasId, uint256 newCanvasRebateRatioInBps);

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(canvasId)) revert NotCanvasOwner();
        require(newCanvasRebateRatioInBps <= 10_000);
        _allCanvases[canvasId].canvasRebateRatioInBps = newCanvasRebateRatioInBps;

        emit CanvasRebateRatioInBpsSet(canvasId, newCanvasRebateRatioInBps);
    }

    function getCanvasRebateRatioInBps(bytes32 canvasId) public view returns (uint256) {
        return _allCanvases[canvasId].canvasRebateRatioInBps;
    }

    event D4AERC721MaxSupplySet(bytes32 indexed daoId, uint256 newMaxSupply);

    function setD4AERC721MaxSupply(bytes32 daoId, uint256 newMaxSupply) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();

        _allProjects[daoId].max_nft_amount = newMaxSupply;

        emit D4AERC721MaxSupplySet(daoId, newMaxSupply);
    }

    event DaoMintableRoundSet(bytes32 daoId, uint256 newMintableRounds);

    function setDaoMintableRound(bytes32 daoId, uint256 newMintableRounds) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();

        _allProjects[daoId].mintable_rounds = newMintableRounds;

        emit DaoMintableRoundSet(daoId, newMintableRounds);
    }

    event DaoTemplateSet(bytes32 daoId, TemplateParam templateParam);

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) public override {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _checkCaller(l.project_proxy);

        _allProjects[daoId].priceTemplateType = templateParam.priceTemplateType;
        _allProjects[daoId].nftPriceFactor = templateParam.priceFactor;
        _allProjects[daoId].rewardTemplateType = templateParam.rewardTemplateType;
        rewardInfo.decayFactor = templateParam.rewardDecayFactor;
        rewardInfo.decayLife = templateParam.rewardDecayLife;
        rewardInfo.isProgressiveJackpot = templateParam.isProgressiveJackpot;

        emit DaoTemplateSet(daoId, templateParam);
    }

    event DaoRatioSet(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    );

    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        public
        override
    {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId) && msg.sender != l.project_proxy) revert NotDaoOwner();
        if (canvasCreatorERC20Ratio + nftMinterERC20Ratio != l.ratio_base) {
            revert InvalidERC20Ratio();
        }
        uint256 ratioBase = l.ratio_base;
        uint256 d4aETHRatio = l.mint_d4a_fee_ratio;
        if (daoFeePoolETHRatioFlatPrice > ratioBase - d4aETHRatio || daoFeePoolETHRatio > daoFeePoolETHRatioFlatPrice) {
            revert InvalidETHRatio();
        }

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        rewardInfo.canvasCreatorERC20RatioInBps = canvasCreatorERC20Ratio;
        rewardInfo.nftMinterERC20RatioInBps = nftMinterERC20Ratio;
        _allProjects[daoId].daoFeePoolETHRatioInBps = daoFeePoolETHRatio;
        _allProjects[daoId].daoFeePoolETHRatioInBpsFlatPrice = daoFeePoolETHRatioFlatPrice;

        emit DaoRatioSet(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );
    }
}

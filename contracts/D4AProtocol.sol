// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// external deps
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { Multicall } from "@solidstate/contracts/utils/Multicall.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

// D4A constants, structs, enums && errors
import { BASIS_POINT } from "contracts/interface/D4AConstants.sol";
import {
    DaoMetadataParam,
    TemplateParam,
    UpdateRewardParam,
    UserMintCapParam,
    DaoMintInfo,
    UserMintInfo,
    MintNftInfo,
    MintVars
} from "contracts/interface/D4AStructs.sol";
import {
    NotDaoOwner,
    NotCanvasOwner,
    NotRole,
    NotCaller,
    Blacklisted,
    NotInWhitelist,
    D4APaused,
    Paused,
    UriAlreadyExist,
    UriNotExist,
    DaoIndexTooLarge,
    DaoIndexAlreadyExist,
    DaoNotExist,
    CanvasNotExist,
    ExceedMinterMaxMintAmount,
    InvalidERC20Ratio,
    InvalidERC20Ratio,
    InvalidETHRatio,
    InvalidSignature,
    PriceTooLow,
    NftExceedMaxAmount,
    NotEnoughEther
} from "contracts/interface/D4AErrors.sol";

// interfaces
import { IPriceTemplate } from "./interface/IPriceTemplate.sol";
import { IRewardTemplate } from "./interface/IRewardTemplate.sol";
import { IPermissionControl } from "./interface/IPermissionControl.sol";
import { ID4AProtocol } from "./interface/ID4AProtocol.sol";
import { ID4AERC721 } from "./interface/ID4AERC721.sol";

// D4A libs, storages && contracts
import { D4AProject } from "./libraries/D4AProject.sol";
import { D4ACanvas } from "./libraries/D4ACanvas.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { SettingsStorage } from "./storages/SettingsStorage.sol";
import { D4AERC20 } from "./D4AERC20.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";

contract D4AProtocol is ID4AProtocol, Multicall, Initializable, ReentrancyGuardUpgradeable, EIP712Upgradeable {
    bytes32 internal constant _MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    using D4AProject for mapping(bytes32 => D4AProject.project_info);
    using D4ACanvas for mapping(bytes32 => D4ACanvas.canvas_info);

    // TODO: add getters for all the mappings
    mapping(bytes32 => D4AProject.project_info) internal _allProjects;
    mapping(bytes32 => D4ACanvas.canvas_info) internal _allCanvases;
    mapping(bytes32 => bytes32) internal _nftHashToCanvasId;

    mapping(bytes32 => bool) public uriExists;

    uint256 public daoIndex;

    uint256 internal _daoIndexBitMap;

    mapping(bytes32 daoId => DaoMintInfo daoMintInfo) internal _daoMintInfos;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        __ReentrancyGuard_init();
        daoIndex = l.reserved_slots;
        __EIP712_init("D4AProtocol", "2");
    }

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

    function _checkPauseStatus() internal view {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.d4a_pause) {
            revert D4APaused();
        }
    }

    modifier notPaused(bytes32 id) {
        _checkPauseStatus(id);
        _;
    }

    function _checkPauseStatus(bytes32 id) internal view {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.pause_status[id]) {
            revert Paused(id);
        }
    }

    modifier uriExist(string calldata uri) {
        _checkUriExist(uri);
        _;
    }

    modifier uriNotExist(string calldata uri) {
        _checkUriNotExist(uri);
        _;
    }

    function _uriExist(string memory uri) internal view returns (bool) {
        return uriExists[keccak256(abi.encodePacked(uri))];
    }

    function _checkUriExist(string calldata uri) internal view {
        if (!_uriExist(uri)) {
            revert UriNotExist(uri);
        }
    }

    function _checkUriNotExist(string memory uri) internal view {
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
        nonReentrant
        d4aNotPaused
        uriNotExist(_project_uri)
        returns (bytes32 project_id)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.project_proxy);
        uriExists[keccak256(abi.encodePacked(_project_uri))] = true;
        project_id = _allProjects.createProject(
            _start_prb, _mintable_rounds, _floor_price_rank, _max_nft_rank, _royalty_fee, daoIndex, _project_uri
        );
        daoIndex++;
    }

    function createOwnerProject(DaoMetadataParam calldata daoMetadataParam)
        public
        payable
        nonReentrant
        d4aNotPaused
        returns (
            // uriNotExist(_project_uri)
            bytes32 project_id
        )
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.project_proxy);
        {
            _checkUriNotExist(daoMetadataParam.projectUri);
        }
        {
            if (daoMetadataParam.projectIndex >= l.reserved_slots) revert DaoIndexTooLarge();
            if (((_daoIndexBitMap >> daoMetadataParam.projectIndex) & 1) != 0) revert DaoIndexAlreadyExist();
        }

        {
            _daoIndexBitMap |= (1 << daoMetadataParam.projectIndex);
            uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;
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

    function createCanvas(
        bytes32 daoId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        uint256 canvasRebateRatioInBps
    )
        external
        payable
        nonReentrant
        returns (bytes32)
    {
        _checkPauseStatus();
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);
        _checkUriNotExist(canvasUri);

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.permission_control.isCanvasCreatorBlacklisted(daoId, msg.sender)) revert Blacklisted();
        if (!l.permission_control.inCanvasCreatorWhitelist(daoId, msg.sender, proof)) {
            revert NotInWhitelist();
        }

        uriExists[keccak256(abi.encodePacked(canvasUri))] = true;

        bytes32 canvasId = _allCanvases.createCanvas(
            _allProjects[daoId].fee_pool,
            daoId,
            _allProjects[daoId].start_prb,
            _allProjects.getProjectCanvasCount(daoId),
            canvasUri
        );

        _allProjects[daoId].canvases.push(canvasId);

        if (canvasRebateRatioInBps != 0) setCanvasRebateRatioInBps(canvasId, canvasRebateRatioInBps);

        return canvasId;
    }

    function _createCanvas(bytes32 _project_id, string calldata _canvas_uri) internal returns (bytes32 canvas_id) { }

    modifier ableToMint(bytes32 daoId, bytes32[] calldata proof, uint256 amount) {
        _checkMintEligibility(daoId, msg.sender, proof, amount);
        _;
    }

    function _checkMintEligibility(
        bytes32 daoId,
        address account,
        bytes32[] calldata proof,
        uint256 amount
    )
        internal
        view
    {
        if (!_ableToMint(daoId, account, proof, amount)) revert ExceedMinterMaxMintAmount();
    }

    function mintNFT(
        bytes32 daoId,
        bytes32 _canvas_id,
        string calldata _token_uri,
        bytes32[] calldata proof,
        uint256 _flat_price,
        bytes calldata _signature
    )
        external
        payable
        nonReentrant
        returns (uint256)
    {
        {
            _checkMintEligibility(daoId, msg.sender, proof, 1);
        }
        _verifySignature(_canvas_id, _token_uri, _flat_price, _signature);
        _daoMintInfos[daoId].userMintInfos[msg.sender].minted += 1;
        return _mintNft(_canvas_id, _token_uri, _flat_price);
    }

    function batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        bytes32[] calldata proof,
        MintNftInfo[] calldata mintNftInfos,
        bytes[] calldata signatures
    )
        external
        payable
        nonReentrant
        returns (uint256[] memory)
    {
        uint32 length = uint32(mintNftInfos.length);
        {
            _checkMintEligibility(daoId, msg.sender, proof, length);
            for (uint32 i = 0; i < length;) {
                _verifySignature(canvasId, mintNftInfos[i].tokenUri, mintNftInfos[i].flatPrice, signatures[i]);
                unchecked {
                    ++i;
                }
            }
        }
        _daoMintInfos[daoId].userMintInfos[msg.sender].minted += length;
        return _batchMint(daoId, canvasId, mintNftInfos);
    }

    function setMintCapAndPermission(
        bytes32 daoId,
        uint32 daoMintCap,
        UserMintCapParam[] calldata userMintCapParams,
        IPermissionControl.Whitelist memory whitelist,
        IPermissionControl.Blacklist memory blacklist,
        IPermissionControl.Blacklist memory unblacklist
    )
        public
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.project_proxy && msg.sender != l.owner_proxy.ownerOf(daoId)) {
            revert NotDaoOwner();
        }
        DaoMintInfo storage daoMintInfo = _daoMintInfos[daoId];
        daoMintInfo.daoMintCap = daoMintCap;
        uint256 length = userMintCapParams.length;
        for (uint256 i = 0; i < length;) {
            daoMintInfo.userMintInfos[userMintCapParams[i].minter].mintCap = userMintCapParams[i].mintCap;
            unchecked {
                ++i;
            }
        }

        emit MintCapSet(daoId, daoMintCap, userMintCapParams);

        l.permission_control.modifyPermission(daoId, whitelist, blacklist, unblacklist);
    }

    function _ableToMint(
        bytes32 daoId,
        address account,
        bytes32[] calldata proof,
        uint256 amount
    )
        internal
        view
        returns (bool)
    {
        // check priority
        // 1. blacklist
        // 2. designated mint cap
        // 3. whitelist (merkle tree || ERC721)
        // 4. DAO mint cap
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        IPermissionControl permissionControl = l.permission_control;
        if (permissionControl.isMinterBlacklisted(daoId, account)) {
            revert Blacklisted();
        }
        uint32 daoMintCap;
        uint128 userMinted;
        uint128 userMintCap;
        {
            DaoMintInfo storage daoMintInfo = _daoMintInfos[daoId];
            daoMintCap = daoMintInfo.daoMintCap;
            UserMintInfo memory userMintInfo = daoMintInfo.userMintInfos[account];
            userMinted = userMintInfo.minted;
            userMintCap = userMintInfo.mintCap;
        }

        bool isWhitelistOff;
        {
            IPermissionControl.Whitelist memory whitelist = permissionControl.getWhitelist(daoId);
            isWhitelistOff = whitelist.minterMerkleRoot == bytes32(0) && whitelist.minterNFTHolderPasses.length == 0;
        }

        uint256 expectedMinted = userMinted + amount;
        // no whitelist
        if (isWhitelistOff) {
            return daoMintCap == 0 ? true : expectedMinted <= daoMintCap;
        }

        // whitelist on && not in whitelist
        if (!permissionControl.inMinterWhitelist(daoId, account, proof)) {
            revert NotInWhitelist();
        }

        // designated mint cap
        return userMintCap != 0 ? expectedMinted <= userMintCap : daoMintCap != 0 ? expectedMinted <= daoMintCap : true;
    }

    function _verifySignature(
        bytes32 _canvas_id,
        string calldata _token_uri,
        uint256 _flat_price,
        bytes calldata _signature
    )
        internal
        view
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_MINTNFT_TYPEHASH, _canvas_id, keccak256(bytes(_token_uri)), _flat_price))
        );
        address signer = ECDSAUpgradeable.recover(digest, _signature);
        if (
            !IAccessControlUpgradeable(address(this)).hasRole(keccak256("SIGNER_ROLE"), signer)
                && signer != l.owner_proxy.ownerOf(_canvas_id)
        ) revert InvalidSignature();
    }

    function getProjectCanvasCount(bytes32 _project_id) public view returns (uint256) {
        return _allProjects.getProjectCanvasCount(_project_id);
    }

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
        SettingsStorage.Layout storage l = SettingsStorage.layout();
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
        if (pi.nft_supply >= pi.max_nft_amount) revert NftExceedMaxAmount();

        {
            bytes32 token_uri_hash = keccak256(abi.encodePacked(_token_uri));
            uriExists[token_uri_hash] = true;
        }

        // get next mint price
        uint256 price;
        {
            uint256 currentRound = l.drb.currentRound();
            uint256 nftPriceFactor = pi.nftPriceFactor;
            price = _getCanvasNextPrice(daoId, canvasId, flatPrice, pi.start_prb, currentRound, nftPriceFactor);
            _updatePrice(currentRound, daoId, canvasId, price, flatPrice, nftPriceFactor);
        }

        // split fee
        uint256 daoFee;
        D4ACanvas.canvas_info storage ci = _allCanvases[canvasId];
        {
            address protocolFeePool = l.protocolFeePool;
            address daoFeePool = pi.fee_pool;
            address canvasOwner = l.owner_proxy.ownerOf(canvasId);
            // uint256 daoShare = (flatPrice == 0 ? l.mint_project_fee_ratio : l.mint_project_fee_ratio_flat_price) *
            uint256 daoShare =
                (flatPrice == 0 ? getDaoFeePoolETHRatio(daoId) : getDaoFeePoolETHRatioFlatPrice(daoId)) * price;

            (daoFee,) = _splitFee(protocolFeePool, daoFeePool, canvasOwner, price, daoShare, ci.canvasRebateRatioInBps);
        }

        _updateReward(daoId, canvasId, daoFee);

        // mint
        token_id = ID4AERC721(pi.erc721_token).mintItem(msg.sender, _token_uri);
        {
            pi.nft_supply++;
            ci.nft_tokens.push(token_id);
            ci.nft_token_number++;
            _nftHashToCanvasId[keccak256(abi.encodePacked(daoId, token_id))] = canvasId;
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
            (bool succ,) = SettingsStorage.layout().priceTemplates[uint8(_allProjects[daoId].priceTemplateType)]
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
        }
    }

    function _batchMint(
        bytes32 daoId,
        bytes32 canvasId,
        MintNftInfo[] memory mintNftInfos
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
        {
            _checkPauseStatus();
            _checkPauseStatus(daoId);
            _checkCanvasExist(canvasId);
            _checkPauseStatus(canvasId);
        }

        uint256 length = uint32(mintNftInfos.length);
        {
            uint256 projectFloorPrice = getProjectFloorPrice(daoId);
            for (uint32 i = 0; i < length;) {
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
        if (pi.nft_supply + length > pi.max_nft_amount) revert NftExceedMaxAmount();

        MintVars memory vars;
        uint256 currentRound = SettingsStorage.layout().drb.currentRound();
        uint256 nftPriceFactor = pi.nftPriceFactor;

        vars.price = _getCanvasNextPrice(daoId, canvasId, 0, pi.start_prb, currentRound, nftPriceFactor);
        vars.initialPrice = vars.price;
        vars.daoTotalShare;
        vars.totalPrice;
        uint256[] memory tokenIds = new uint256[](length);
        pi.nft_supply += length;
        ci.nft_token_number += length;
        for (uint32 i; i < length;) {
            uriExists[keccak256(abi.encodePacked(mintNftInfos[i].tokenUri))] = true;
            tokenIds[i] = ID4AERC721(pi.erc721_token).mintItem(msg.sender, mintNftInfos[i].tokenUri);
            ci.nft_tokens.push(tokenIds[i]);
            _nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenIds[i]))] = canvasId;
            uint256 flatPrice = mintNftInfos[i].flatPrice;
            SettingsStorage.Layout storage l = SettingsStorage.layout();
            if (flatPrice == 0) {
                vars.daoTotalShare += l.mint_project_fee_ratio * vars.price;
                vars.totalPrice += vars.price;
                emit D4AMintNFT(daoId, canvasId, tokenIds[i], mintNftInfos[i].tokenUri, vars.price);
                vars.price = vars.price * nftPriceFactor / BASIS_POINT;
            } else {
                vars.daoTotalShare += l.mint_project_fee_ratio_flat_price * flatPrice;
                vars.totalPrice += flatPrice;
                emit D4AMintNFT(daoId, canvasId, tokenIds[i], mintNftInfos[i].tokenUri, flatPrice);
            }
            unchecked {
                ++i;
            }
        }

        {
            // split fee
            SettingsStorage.Layout storage l = SettingsStorage.layout();
            address protocolFeePool = l.protocolFeePool;
            address daoFeePool = pi.fee_pool;
            address canvasOwner = l.owner_proxy.ownerOf(canvasId);

            (vars.daoFee,) = _splitFee(
                protocolFeePool, daoFeePool, canvasOwner, vars.totalPrice, vars.daoTotalShare, ci.canvasRebateRatioInBps
            );
        }

        // update canvas price
        if (vars.price != vars.initialPrice) {
            vars.price = vars.price * BASIS_POINT / nftPriceFactor;
            _updatePrice(currentRound, daoId, canvasId, vars.price, 0, nftPriceFactor);
        }

        _updateReward(daoId, canvasId, vars.daoFee);

        return tokenIds;
    }

    function _getCanvasNextPrice(
        bytes32 daoId,
        bytes32 canvasId,
        uint256 flatPrice,
        uint256 startRound,
        uint256 currentRound,
        uint256 priceFactor
    )
        internal
        view
        returns (uint256 price)
    {
        PriceStorage.Layout storage priceStorage = PriceStorage.layout();
        uint256 daoFloorPrice = priceStorage.daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = priceStorage.daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = priceStorage.canvasLastMintInfos[canvasId];
        if (flatPrice == 0) {
            price = IPriceTemplate(
                SettingsStorage.layout().priceTemplates[uint8(_allProjects[daoId].priceTemplateType)]
            ).getCanvasNextPrice(startRound, currentRound, priceFactor, daoFloorPrice, maxPrice, mintInfo);
        } else {
            price = flatPrice;
        }
    }

    function _updateReward(bytes32 daoId, bytes32 canvasId, uint256 daoFeeAmount) internal {
        D4AProject.project_info memory pi = _allProjects[daoId];
        D4ACanvas.canvas_info memory ci = _allCanvases[canvasId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        (bool succ,) = SettingsStorage.layout().rewardTemplates[uint8(_allProjects[daoId].rewardTemplateType)]
            .delegatecall(
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
                    getCanvasCreatorERC20Ratio(daoId),
                    getNftMinterERC20Ratio(daoId),
                    ci.canvasRebateRatioInBps
                )
            )
        );
        if (!succ) {
            /// @solidity memory-safe-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

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
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        daoFee = daoShare / BASIS_POINT;
        protocolFee = price * l.mint_d4a_fee_ratio / BASIS_POINT;
        uint256 canvasFee = price - daoFee - protocolFee;
        uint256 rebateAmount = canvasFee * canvasRebateRatioInBps / BASIS_POINT;
        canvasFee -= rebateAmount;
        if (msg.value < price - rebateAmount) revert NotEnoughEther();
        uint256 exchange = msg.value - price + rebateAmount;

        if (protocolFee > 0) SafeTransferLib.safeTransferETH(protocolFeePool, protocolFee);
        if (daoFee > 0) SafeTransferLib.safeTransferETH(daoFeePool, daoFee);
        if (canvasFee > 0) SafeTransferLib.safeTransferETH(canvasOwner, canvasFee);
        if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
    }

    function getNFTTokenCanvas(bytes32 _project_id, uint256 _token_id) public view returns (bytes32) {
        return _nftHashToCanvasId[keccak256(abi.encodePacked(_project_id, _token_id))];
    }

    function claimProjectERC20Reward(bytes32 daoId)
        public
        nonReentrant
        d4aNotPaused
        notPaused(daoId)
        daoExist(daoId)
        returns (uint256)
    {
        D4AProject.project_info storage pi = _allProjects[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = SettingsStorage.layout().rewardTemplates[uint8(
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
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = SettingsStorage.layout().rewardTemplates[uint8(
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
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = SettingsStorage.layout().rewardTemplates[uint8(
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
        uint256 tokenAmount,
        address to
    )
        public
        nonReentrant
        d4aNotPaused
        notPaused(daoId)
        returns (uint256)
    {
        D4AProject.project_info storage pi = _allProjects[daoId];

        address token = pi.erc20_token;
        address daoFeePool = pi.fee_pool;

        D4AERC20(token).burn(msg.sender, tokenAmount);
        D4AERC20(token).mint(daoFeePool, tokenAmount);

        uint256 currentRound = SettingsStorage.layout().drb.currentRound();

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256 tokenCirculation = rewardInfo.totalReward * rewardInfo.activeRounds.length / pi.mintable_rounds
            + tokenAmount - D4AERC20(token).balanceOf(daoFeePool);

        if (tokenCirculation == 0) return 0;

        uint256 avalaibleETH = daoFeePool.balance - rewardInfo.totalWeights[currentRound];
        uint256 ethAmount = tokenAmount * avalaibleETH / tokenCirculation;

        if (ethAmount != 0) D4AFeePool(payable(daoFeePool)).transfer(address(0x0), payable(to), ethAmount);

        emit D4AExchangeERC20ToETH(daoId, msg.sender, to, tokenAmount, ethAmount);

        return ethAmount;
    }

    function changeDaoNftPriceMultiplyFactor(bytes32 daoId, uint256 nftPriceFactor) public onlyRole(bytes32(0)) {
        require(nftPriceFactor >= 10_000);
        _allProjects[daoId].nftPriceFactor = nftPriceFactor;

        emit DaoNftPriceMultiplyFactorChanged(daoId, nftPriceFactor);
    }

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(canvasId)) revert NotCanvasOwner();
        require(newCanvasRebateRatioInBps <= 10_000);
        _allCanvases[canvasId].canvasRebateRatioInBps = newCanvasRebateRatioInBps;

        emit CanvasRebateRatioInBpsSet(canvasId, newCanvasRebateRatioInBps);
    }

    function getCanvasRebateRatioInBps(bytes32 canvasId) public view returns (uint256) {
        return _allCanvases[canvasId].canvasRebateRatioInBps;
    }

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();

        _allProjects[daoId].max_nft_amount = newMaxSupply;

        emit DaoNftMaxSupplySet(daoId, newMaxSupply);
    }

    function setDaoMintableRound(bytes32 daoId, uint256 newMintableRounds) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();

        _allProjects[daoId].mintable_rounds = newMintableRounds;

        emit DaoMintableRoundSet(daoId, newMintableRounds);
    }

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
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

    function setRatio(
        bytes32 daoId,
        uint256 canvasCreatorERC20Ratio,
        uint256 nftMinterERC20Ratio,
        uint256 daoFeePoolETHRatio,
        uint256 daoFeePoolETHRatioFlatPrice
    )
        public
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId) && msg.sender != l.project_proxy) revert NotDaoOwner();
        if (canvasCreatorERC20Ratio + nftMinterERC20Ratio != BASIS_POINT) {
            revert InvalidERC20Ratio();
        }
        uint256 d4aETHRatio = l.mint_d4a_fee_ratio;
        if (daoFeePoolETHRatioFlatPrice > BASIS_POINT - d4aETHRatio || daoFeePoolETHRatio > daoFeePoolETHRatioFlatPrice)
        {
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

    /*////////////////////////////////////////////////
                         Getters                     
    ////////////////////////////////////////////////*/
    function getDaoMintCap(bytes32 daoId) public view returns (uint32) {
        return _daoMintInfos[daoId].daoMintCap;
    }

    function getUserMintInfo(bytes32 daoId, address account) public view returns (uint32 minted, uint32 userMintCap) {
        minted = _daoMintInfos[daoId].userMintInfos[account].minted;
        userMintCap = _daoMintInfos[daoId].userMintInfos[account].mintCap;
    }

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
        PriceStorage.MintInfo storage mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        return (mintInfo.round, mintInfo.price);
    }

    function getCanvasNextPrice(bytes32 canvasId) public view returns (uint256) {
        bytes32 daoId = _allCanvases[canvasId].project_id;
        uint256 daoFloorPrice = PriceStorage.layout().daoFloorPrices[daoId];
        PriceStorage.MintInfo memory maxPrice = PriceStorage.layout().daoMaxPrices[daoId];
        PriceStorage.MintInfo memory mintInfo = PriceStorage.layout().canvasLastMintInfos[canvasId];
        D4AProject.project_info storage pi = _allProjects[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        return IPriceTemplate(l.priceTemplates[uint8(_allProjects[daoId].priceTemplateType)]).getCanvasNextPrice(
            pi.start_prb, l.drb.currentRound(), pi.nftPriceFactor, daoFloorPrice, maxPrice, mintInfo
        );
    }

    function getCanvasCreatorERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 canvasCreatorERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].canvasCreatorERC20RatioInBps;
        if (canvasCreatorERC20RatioInBps == 0) {
            return l.canvas_erc20_ratio;
        }
        return canvasCreatorERC20RatioInBps * (BASIS_POINT - l.protocolERC20RatioInBps - l.daoCreatorERC20RatioInBps)
            / BASIS_POINT;
    }

    function getNftMinterERC20Ratio(bytes32 daoId) public view returns (uint256) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        uint256 nftMinterERC20RatioInBps = RewardStorage.layout().rewardInfos[daoId].nftMinterERC20RatioInBps;
        if (nftMinterERC20RatioInBps == 0) {
            return 0;
        }
        return nftMinterERC20RatioInBps * (BASIS_POINT - l.protocolERC20RatioInBps - l.daoCreatorERC20RatioInBps)
            / BASIS_POINT;
    }

    function getDaoFeePoolETHRatio(bytes32 daoId) public view returns (uint256) {
        if (_allProjects[daoId].daoFeePoolETHRatioInBps == 0) {
            return SettingsStorage.layout().mint_project_fee_ratio;
        }
        return _allProjects[daoId].daoFeePoolETHRatioInBps;
    }

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) public view returns (uint256) {
        if (_allProjects[daoId].daoFeePoolETHRatioInBpsFlatPrice == 0) {
            return SettingsStorage.layout().mint_project_fee_ratio_flat_price;
        }
        return _allProjects[daoId].daoFeePoolETHRatioInBpsFlatPrice;
    }
}

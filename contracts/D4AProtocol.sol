// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

// external deps
import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { Multicallable } from "solady/utils/Multicallable.sol";

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
import "contracts/interface/D4AErrors.sol";

// interfaces
import { IPriceTemplate } from "./interface/IPriceTemplate.sol";
import { IRewardTemplate } from "./interface/IRewardTemplate.sol";
import { IPermissionControl } from "./interface/IPermissionControl.sol";
import { ID4AProtocolReadable } from "./interface/ID4AProtocolReadable.sol";
import { ID4AProtocol } from "./interface/ID4AProtocol.sol";
import { ID4AChangeAdmin } from "./interface/ID4AChangeAdmin.sol";

// D4A storages && contracts
import { DaoStorage } from "contracts/storages/DaoStorage.sol";
import { CanvasStorage } from "contracts/storages/CanvasStorage.sol";
import { PriceStorage } from "contracts/storages/PriceStorage.sol";
import { RewardStorage } from "./storages/RewardStorage.sol";
import { SettingsStorage } from "./storages/SettingsStorage.sol";
import { D4AERC20 } from "./D4AERC20.sol";
import { D4AERC721 } from "./D4AERC721.sol";
import { D4AFeePool } from "./feepool/D4AFeePool.sol";

contract D4AProtocol is ID4AProtocol, Multicallable, Initializable, ReentrancyGuardUpgradeable, EIP712Upgradeable {
    bytes32 internal constant _MINTNFT_TYPEHASH =
        keccak256("MintNFT(bytes32 canvasID,bytes32 tokenURIHash,uint256 flatPrice)");

    mapping(bytes32 => bytes32) internal _nftHashToCanvasId;

    mapping(bytes32 => bool) public uriExists;

    uint256 internal _daoIndex;

    uint256 internal _daoIndexBitMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        __ReentrancyGuard_init();
        _daoIndex = l.reserved_slots;
        __EIP712_init("D4AProtocol", "2");
    }

    function createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        string calldata daoUri
    )
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        _checkPauseStatus();
        _checkUriNotExist(daoUri);
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.project_proxy);
        uriExists[keccak256(abi.encodePacked(daoUri))] = true;
        daoId = _createProject(
            startRound, mintableRound, daoFloorPriceRank, nftMaxSupplyRank, royaltyFeeRatioInBps, _daoIndex, daoUri
        );
        _daoIndex++;
    }

    function createOwnerProject(DaoMetadataParam calldata daoMetadataParam)
        public
        payable
        nonReentrant
        returns (bytes32 daoId)
    {
        _checkPauseStatus();

        SettingsStorage.Layout storage l = SettingsStorage.layout();
        _checkCaller(l.project_proxy);
        _checkUriNotExist(daoMetadataParam.projectUri);
        {
            if (daoMetadataParam.projectIndex >= l.reserved_slots) revert DaoIndexTooLarge();
            if (((_daoIndexBitMap >> daoMetadataParam.projectIndex) & 1) != 0) revert DaoIndexAlreadyExist();
        }

        {
            _daoIndexBitMap |= (1 << daoMetadataParam.projectIndex);
            uriExists[keccak256(abi.encodePacked(daoMetadataParam.projectUri))] = true;
        }
        {
            return _createProject(
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

        bytes32 canvasId = _createCanvas(
            CanvasStorage.layout().canvasInfos,
            DaoStorage.layout().daoInfos[daoId].daoFeePool,
            daoId,
            DaoStorage.layout().daoInfos[daoId].startRound,
            getProjectCanvasCount(daoId),
            canvasUri
        );

        DaoStorage.layout().daoInfos[daoId].canvases.push(canvasId);

        if (canvasRebateRatioInBps != 0) setCanvasRebateRatioInBps(canvasId, canvasRebateRatioInBps);

        return canvasId;
    }

    modifier ableToMint(bytes32 daoId, bytes32[] calldata proof, uint256 amount) {
        _checkMintEligibility(daoId, msg.sender, proof, amount);
        _;
    }

    function mintNFT(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata tokenUri,
        bytes32[] calldata proof,
        uint256 nftFlatPrice,
        bytes calldata signature
    )
        external
        payable
        nonReentrant
        returns (uint256)
    {
        {
            _checkMintEligibility(daoId, msg.sender, proof, 1);
        }
        _verifySignature(canvasId, tokenUri, nftFlatPrice, signature);
        DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[msg.sender].minted += 1;
        return _mintNft(canvasId, tokenUri, nftFlatPrice);
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
        DaoStorage.layout().daoInfos[daoId].daoMintInfo.userMintInfos[msg.sender].minted += length;
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
        DaoMintInfo storage daoMintInfo = DaoStorage.layout().daoInfos[daoId].daoMintInfo;
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

    function getProjectCanvasCount(bytes32 daoId) public view returns (uint256) {
        return DaoStorage.layout().daoInfos[daoId].canvases.length;
    }

    function claimProjectERC20Reward(bytes32 daoId) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkPauseStatus(daoId);
        _checkDaoExist(daoId);
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = SettingsStorage.layout().rewardTemplates[uint8(daoInfo.rewardTemplateType)]
            .delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimDaoCreatorReward.selector,
                daoId,
                l.protocolFeePool,
                l.owner_proxy.ownerOf(daoId),
                daoInfo.startRound,
                l.drb.currentRound(),
                daoInfo.mintableRound,
                daoInfo.token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimProjectERC20Reward(daoId, daoInfo.token, amount);

        return amount;
    }

    function claimCanvasReward(bytes32 canvasId) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkPauseStatus(canvasId);
        _checkCanvasExist(canvasId);
        bytes32 daoId = CanvasStorage.layout().canvasInfos[canvasId].daoId;
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = SettingsStorage.layout().rewardTemplates[uint8(daoInfo.rewardTemplateType)]
            .delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimCanvasCreatorReward.selector,
                daoId,
                canvasId,
                l.owner_proxy.ownerOf(canvasId),
                daoInfo.startRound,
                l.drb.currentRound(),
                daoInfo.mintableRound,
                daoInfo.token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimCanvasReward(daoId, canvasId, daoInfo.token, amount);

        return amount;
    }

    function claimNftMinterReward(bytes32 daoId, address minter) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkDaoExist(daoId);
        _checkPauseStatus(daoId);
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        (bool succ, bytes memory data) = SettingsStorage.layout().rewardTemplates[uint8(daoInfo.rewardTemplateType)]
            .delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.claimNftMinterReward.selector,
                daoId,
                minter,
                daoInfo.startRound,
                l.drb.currentRound(),
                daoInfo.mintableRound,
                daoInfo.token
            )
        );
        require(succ);
        uint256 amount = abi.decode(data, (uint256));

        emit D4AClaimNftMinterReward(daoId, daoInfo.token, amount);

        return amount;
    }

    function exchangeERC20ToETH(bytes32 daoId, uint256 tokenAmount, address to) public nonReentrant returns (uint256) {
        _checkPauseStatus();
        _checkPauseStatus(daoId);
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        address token = daoInfo.token;
        address daoFeePool = daoInfo.daoFeePool;

        D4AERC20(token).burn(msg.sender, tokenAmount);
        D4AERC20(token).mint(daoFeePool, tokenAmount);

        uint256 currentRound = SettingsStorage.layout().drb.currentRound();

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256 tokenCirculation = rewardInfo.totalReward * rewardInfo.activeRounds.length / daoInfo.mintableRound
            + tokenAmount - D4AERC20(token).balanceOf(daoFeePool);

        if (tokenCirculation == 0) return 0;

        uint256 avalaibleETH = daoFeePool.balance - rewardInfo.totalWeights[currentRound];
        uint256 ethAmount = tokenAmount * avalaibleETH / tokenCirculation;

        if (ethAmount != 0) D4AFeePool(payable(daoFeePool)).transfer(address(0x0), payable(to), ethAmount);

        emit D4AExchangeERC20ToETH(daoId, msg.sender, to, tokenAmount, ethAmount);

        return ethAmount;
    }

    function changeDaoNftPriceMultiplyFactor(bytes32 daoId, uint256 nftPriceFactor) public {
        _checkRole(bytes32(0));
        require(nftPriceFactor >= 10_000);
        DaoStorage.layout().daoInfos[daoId].nftPriceFactor = nftPriceFactor;

        emit DaoNftPriceMultiplyFactorChanged(daoId, nftPriceFactor);
    }

    function setCanvasRebateRatioInBps(bytes32 canvasId, uint256 newCanvasRebateRatioInBps) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(canvasId)) revert NotCanvasOwner();
        require(newCanvasRebateRatioInBps <= 10_000);
        CanvasStorage.layout().canvasInfos[canvasId].canvasRebateRatioInBps = newCanvasRebateRatioInBps;

        emit CanvasRebateRatioInBpsSet(canvasId, newCanvasRebateRatioInBps);
    }

    function getCanvasRebateRatioInBps(bytes32 canvasId) public view returns (uint256) {
        return CanvasStorage.layout().canvasInfos[canvasId].canvasRebateRatioInBps;
    }

    function setDaoNftMaxSupply(bytes32 daoId, uint256 newMaxSupply) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();

        DaoStorage.layout().daoInfos[daoId].nftMaxSupply = newMaxSupply;

        emit DaoNftMaxSupplySet(daoId, newMaxSupply);
    }

    function setDaoMintableRound(bytes32 daoId, uint256 newMintableRound) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();
        if (newMintableRound > l.project_max_rounds) revert ExceedMaxMintableRound();

        DaoStorage.layout().daoInfos[daoId].mintableRound = newMintableRound;

        emit DaoMintableRoundSet(daoId, newMintableRound);
    }

    function setDaoFloorPrice(bytes32 daoId, uint256 newFloorPrice) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (msg.sender != l.owner_proxy.ownerOf(daoId)) revert NotDaoOwner();

        PriceStorage.layout().daoFloorPrices[daoId] = newFloorPrice;

        emit DaoFloorPriceSet(daoId, newFloorPrice);
    }

    function setTemplate(bytes32 daoId, TemplateParam calldata templateParam) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if (msg.sender != l.owner_proxy.ownerOf(daoId) && msg.sender != l.project_proxy) revert NotDaoOwner();

        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        _checkCaller(l.project_proxy);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        daoInfo.priceTemplateType = templateParam.priceTemplateType;
        daoInfo.nftPriceFactor = templateParam.priceFactor;
        daoInfo.rewardTemplateType = templateParam.rewardTemplateType;
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
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        daoInfo.daoFeePoolETHRatioInBps = daoFeePoolETHRatio;
        daoInfo.daoFeePoolETHRatioInBpsFlatPrice = daoFeePoolETHRatioFlatPrice;

        emit DaoRatioSet(
            daoId, canvasCreatorERC20Ratio, nftMinterERC20Ratio, daoFeePoolETHRatio, daoFeePoolETHRatioFlatPrice
        );
    }

    ///////////////////////////////////////////
    // Getters
    ///////////////////////////////////////////

    function getNFTTokenCanvas(bytes32 daoId, uint256 tokenId) public view returns (bytes32) {
        return _nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenId))];
    }

    function _checkRole(bytes32 role) internal view virtual {
        if (!_hasRole(role, msg.sender)) {
            revert NotRole(role, msg.sender);
        }
    }

    function _checkDaoExist(bytes32 daoId) internal view {
        if (!DaoStorage.layout().daoInfos[daoId].daoExist) revert DaoNotExist();
    }

    function _checkCanvasExist(bytes32 canvasId) internal view {
        if (!CanvasStorage.layout().canvasInfos[canvasId].canvasExist) revert CanvasNotExist();
    }

    function _hasRole(bytes32 role, address account) internal view virtual returns (bool) {
        return IAccessControlUpgradeable(address(this)).hasRole(role, account);
    }

    function _checkCaller(address caller) internal view {
        if (caller != msg.sender) {
            revert NotCaller(caller);
        }
    }

    function _checkPauseStatus() internal view {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.d4a_pause) {
            revert D4APaused();
        }
    }

    function _checkPauseStatus(bytes32 id) internal view {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (l.pause_status[id]) {
            revert Paused(id);
        }
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
            DaoMintInfo storage daoMintInfo = DaoStorage.layout().daoInfos[daoId].daoMintInfo;
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
        bytes32 canvasId,
        string calldata tokenUri,
        uint256 nftFlatPrice,
        bytes calldata signature
    )
        internal
        view
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_MINTNFT_TYPEHASH, canvasId, keccak256(bytes(tokenUri)), nftFlatPrice))
        );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        if (
            !IAccessControlUpgradeable(address(this)).hasRole(keccak256("SIGNER_ROLE"), signer)
                && signer != l.owner_proxy.ownerOf(canvasId)
        ) revert InvalidSignature();
    }

    function _mintNft(
        bytes32 canvasId,
        string calldata tokenUri,
        uint256 flatPrice
    )
        internal
        returns (uint256 tokenId)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        {
            _checkPauseStatus();
            _checkPauseStatus(canvasId);
            _checkCanvasExist(canvasId);
            _checkUriNotExist(tokenUri);
        }
        bytes32 daoId = CanvasStorage.layout().canvasInfos[canvasId].daoId;

        if (flatPrice != 0 && flatPrice < ID4AProtocolReadable(address(this)).getProjectFloorPrice(daoId)) {
            revert PriceTooLow();
        }
        _checkPauseStatus(daoId);

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        if (daoInfo.nftTotalSupply >= daoInfo.nftMaxSupply) revert NftExceedMaxAmount();

        uriExists[keccak256(abi.encodePacked(tokenUri))] = true;

        // get next mint price
        uint256 price;
        {
            uint256 currentRound = l.drb.currentRound();
            uint256 nftPriceFactor = daoInfo.nftPriceFactor;
            price = _getCanvasNextPrice(daoId, canvasId, flatPrice, daoInfo.startRound, currentRound, nftPriceFactor);
            _updatePrice(currentRound, daoId, canvasId, price, flatPrice, nftPriceFactor);
        }

        // split fee
        uint256 daoFee;
        CanvasStorage.CanvasInfo storage canvasInfo = CanvasStorage.layout().canvasInfos[canvasId];
        {
            address protocolFeePool = l.protocolFeePool;
            address daoFeePool = daoInfo.daoFeePool;
            address canvasOwner = l.owner_proxy.ownerOf(canvasId);
            uint256 daoShare = (
                flatPrice == 0
                    ? ID4AProtocolReadable(address(this)).getDaoFeePoolETHRatio(daoId)
                    : ID4AProtocolReadable(address(this)).getDaoFeePoolETHRatioFlatPrice(daoId)
            ) * price;

            (daoFee,) =
                _splitFee(protocolFeePool, daoFeePool, canvasOwner, price, daoShare, canvasInfo.canvasRebateRatioInBps);
        }

        _updateReward(daoId, canvasId, daoFee);

        // mint
        tokenId = D4AERC721(daoInfo.nft).mintItem(msg.sender, tokenUri);
        {
            daoInfo.nftTotalSupply++;
            canvasInfo.tokenIds.push(tokenId);
            canvasInfo.nft_token_number++;
            _nftHashToCanvasId[keccak256(abi.encodePacked(daoId, tokenId))] = canvasId;
        }

        emit D4AMintNFT(daoId, canvasId, tokenId, tokenUri, price);
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
            (bool succ,) = SettingsStorage.layout().priceTemplates[uint8(
                DaoStorage.layout().daoInfos[daoId].priceTemplateType
            )].delegatecall(
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
        returns (uint256[] memory)
    {
        {
            _checkPauseStatus();
            _checkPauseStatus(daoId);
            _checkCanvasExist(canvasId);
            _checkPauseStatus(canvasId);
        }

        uint256 length = uint32(mintNftInfos.length);
        {
            uint256 projectFloorPrice = ID4AProtocolReadable(address(this)).getProjectFloorPrice(daoId);
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

        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        CanvasStorage.CanvasInfo storage canvasInfo = CanvasStorage.layout().canvasInfos[canvasId];
        if (daoInfo.nftTotalSupply + length > daoInfo.nftMaxSupply) revert NftExceedMaxAmount();

        MintVars memory vars;
        uint256 currentRound = SettingsStorage.layout().drb.currentRound();
        uint256 nftPriceFactor = daoInfo.nftPriceFactor;

        vars.price = _getCanvasNextPrice(daoId, canvasId, 0, daoInfo.startRound, currentRound, nftPriceFactor);
        vars.initialPrice = vars.price;
        vars.daoTotalShare;
        vars.totalPrice;
        uint256[] memory tokenIds = new uint256[](length);
        daoInfo.nftTotalSupply += length;
        canvasInfo.nft_token_number += length;
        for (uint32 i; i < length;) {
            uriExists[keccak256(abi.encodePacked(mintNftInfos[i].tokenUri))] = true;
            tokenIds[i] = D4AERC721(daoInfo.nft).mintItem(msg.sender, mintNftInfos[i].tokenUri);
            canvasInfo.tokenIds.push(tokenIds[i]);
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
            address daoFeePool = daoInfo.daoFeePool;
            address canvasOwner = l.owner_proxy.ownerOf(canvasId);

            (vars.daoFee,) = _splitFee(
                protocolFeePool,
                daoFeePool,
                canvasOwner,
                vars.totalPrice,
                vars.daoTotalShare,
                canvasInfo.canvasRebateRatioInBps
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
                SettingsStorage.layout().priceTemplates[uint8(DaoStorage.layout().daoInfos[daoId].priceTemplateType)]
            ).getCanvasNextPrice(startRound, currentRound, priceFactor, daoFloorPrice, maxPrice, mintInfo);
        } else {
            price = flatPrice;
        }
    }

    function _updateReward(bytes32 daoId, bytes32 canvasId, uint256 daoFeeAmount) internal {
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];
        CanvasStorage.CanvasInfo memory canvasInfo = CanvasStorage.layout().canvasInfos[canvasId];
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        (bool succ,) = SettingsStorage.layout().rewardTemplates[uint8(
            DaoStorage.layout().daoInfos[daoId].rewardTemplateType
        )].delegatecall(
            abi.encodeWithSelector(
                IRewardTemplate.updateReward.selector,
                UpdateRewardParam(
                    daoId,
                    canvasId,
                    daoInfo.startRound,
                    l.drb.currentRound(),
                    daoInfo.mintableRound,
                    daoFeeAmount,
                    l.protocolERC20RatioInBps,
                    l.daoCreatorERC20RatioInBps,
                    ID4AProtocolReadable(address(this)).getCanvasCreatorERC20Ratio(daoId),
                    ID4AProtocolReadable(address(this)).getNftMinterERC20Ratio(daoId),
                    canvasInfo.canvasRebateRatioInBps
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

    function _createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        uint256 daoIndex,
        string memory daoUri
    )
        internal
        returns (bytes32 daoId)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        if (mintableRound > l.project_max_rounds) revert ExceedMaxMintableRound();
        {
            uint256 protocol_fee = l.mint_d4a_fee_ratio;
            if (
                royaltyFeeRatioInBps < l.rf_lower_bound + protocol_fee
                    || royaltyFeeRatioInBps > l.rf_upper_bound + protocol_fee
            ) revert RoyaltyFeeRatioOutOfRange();
        }
        {
            uint256 minimal = l.create_project_fee;
            if (msg.value < minimal) revert NotEnoughEther();

            SafeTransferLib.safeTransferETH(l.protocolFeePool, minimal);
            uint256 exchange = msg.value - minimal;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }

        daoId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        DaoStorage.DaoInfo storage daoInfo = DaoStorage.layout().daoInfos[daoId];

        if (daoInfo.daoExist) revert D4AProjectAlreadyExist(daoId);
        {
            if (startRound < l.drb.currentRound()) revert StartRoundAlreadyPassed();
            daoInfo.startRound = startRound;
            daoInfo.mintableRound = mintableRound;
            daoInfo.nftMaxSupply = l.max_nft_amounts[nftMaxSupplyRank];
            daoInfo.daoUri = daoUri;
            daoInfo.royaltyFeeInBps = royaltyFeeRatioInBps;
            daoInfo.daoIndex = daoIndex;
            daoInfo.token = _createERC20Token(daoIndex);

            D4AERC20(daoInfo.token).grantRole(keccak256("MINTER"), address(this));
            D4AERC20(daoInfo.token).grantRole(keccak256("BURNER"), address(this));

            address pool = l.feepool_factory.createD4AFeePool(
                string(abi.encodePacked("Asset Pool for DAO4Art Project ", StringsUpgradeable.toString(daoIndex)))
            );

            D4AFeePool(payable(pool)).grantRole(keccak256("AUTO_TRANSFER"), address(this));

            ID4AChangeAdmin(pool).changeAdmin(l.asset_pool_owner);
            ID4AChangeAdmin(daoInfo.token).changeAdmin(l.asset_pool_owner);

            daoInfo.daoFeePool = pool;

            l.owner_proxy.initOwnerOf(daoId, msg.sender);

            daoInfo.nft = _createERC721Token(daoIndex);
            D4AERC721(daoInfo.nft).grantRole(keccak256("ROYALTY"), msg.sender);
            D4AERC721(daoInfo.nft).grantRole(keccak256("MINTER"), address(this));

            D4AERC721(daoInfo.nft).setContractUri(daoUri);
            ID4AChangeAdmin(daoInfo.nft).changeAdmin(l.asset_pool_owner);
            ID4AChangeAdmin(daoInfo.nft).transferOwnership(msg.sender);
            //We copy from setting in case setting may change later.
            daoInfo.tokenMaxSupply = l.erc20_total_supply;

            if (daoFloorPriceRank != 9999) {
                // 9999 is specified for 0 floor price
                PriceStorage.layout().daoFloorPrices[daoId] = l.floor_prices[daoFloorPriceRank];
            }
            RewardStorage.layout().rewardInfos[daoId].totalReward = l.erc20_total_supply;
            // TODO: remove this to save gas? because impossible to mint NFT at round 0, or change prb such that it
            // starts at round 1
            RewardStorage.layout().rewardInfos[daoId].rewardPendingRound = type(uint256).max;

            daoInfo.daoExist = true;
            emit NewProject(daoId, daoUri, pool, daoInfo.token, daoInfo.nft, royaltyFeeRatioInBps);
        }
    }

    function _createERC20Token(uint256 daoIndex) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = string(abi.encodePacked("D4A Token for No.", StringsUpgradeable.toString(daoIndex)));
        string memory sym = string(abi.encodePacked("D4A.T", StringsUpgradeable.toString(daoIndex)));
        return l.erc20_factory.createD4AERC20(name, sym, address(this));
    }

    function _createERC721Token(uint256 daoIndex) internal returns (address) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        string memory name = string(abi.encodePacked("D4A NFT for No.", StringsUpgradeable.toString(daoIndex)));
        string memory sym = string(abi.encodePacked("D4A.N", StringsUpgradeable.toString(daoIndex)));
        return l.erc721_factory.createD4AERC721(name, sym);
    }

    function _createCanvas(
        mapping(bytes32 => CanvasStorage.CanvasInfo) storage canvasInfos,
        address daoFeePool,
        bytes32 daoId,
        uint256 daoStartRound,
        uint256 canvasIndex,
        string memory canvasUri
    )
        internal
        returns (bytes32)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        {
            uint256 cur_round = l.drb.currentRound();
            if (cur_round < daoStartRound) revert DaoNotStarted();
        }

        {
            uint256 minimal = l.create_canvas_fee;
            if (msg.value < minimal) revert NotEnoughEther();

            SafeTransferLib.safeTransferETH(daoFeePool, minimal);

            uint256 exchange = msg.value - minimal;
            if (exchange > 0) SafeTransferLib.safeTransferETH(msg.sender, exchange);
        }
        bytes32 canvasId = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));
        if (canvasInfos[canvasId].canvasExist) revert D4ACanvasAlreadyExist(canvasId);

        {
            CanvasStorage.CanvasInfo storage canvasInfo = canvasInfos[canvasId];
            canvasInfo.daoId = daoId;
            canvasInfo.canvasUri = canvasUri;
            canvasInfo.index = canvasIndex + 1;
            l.owner_proxy.initOwnerOf(canvasId, msg.sender);
            canvasInfo.canvasExist = true;
        }
        emit NewCanvas(daoId, canvasId, canvasUri);
        return canvasId;
    }
}

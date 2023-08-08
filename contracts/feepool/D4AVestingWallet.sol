// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract D4AVestingWallet {
    error ZeroAddress();
    error InvalidAmount();

    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address => uint256) private _erc20Released;
    address private immutable _beneficiary;

    uint256 internal _lastUpdatedDaoTokenIncrease;
    mapping(address token => uint256 lastUpdatedDaoTokenIssuance) internal _lastUpdatedDaoTokenIncreases;

    address internal immutable _daoToken;
    uint256 internal immutable _totalDaoTokenIssuance;
    uint256 internal immutable _initDaoTokenBalance;

    constructor(address beneficiaryAddress, address daoToken, uint256 totalDaoTokenIssuance) payable {
        if (beneficiaryAddress == address(0) || daoToken == address(0)) revert ZeroAddress();
        if (totalDaoTokenIssuance == 0) revert InvalidAmount();

        _beneficiary = beneficiaryAddress;
        _daoToken = daoToken;
        _initDaoTokenBalance = IERC20(_daoToken).totalSupply();
        _totalDaoTokenIssuance = totalDaoTokenIssuance;
    }

    function release() public virtual {
        uint256 amount = releasable();
        if (amount > 0) {
            _released += amount;
            _lastUpdatedDaoTokenIncrease = IERC20(_daoToken).totalSupply() - _initDaoTokenBalance;
            emit EtherReleased(amount);
            SafeTransferLib.safeTransferETH(payable(beneficiary()), amount);
        }
    }

    function release(address token) public virtual {
        uint256 amount = releasable(token);
        if (amount > 0) {
            _erc20Released[token] += amount;
            _lastUpdatedDaoTokenIncreases[token] = IERC20(_daoToken).totalSupply() - _initDaoTokenBalance;
            emit ERC20Released(token, amount);
            SafeTransferLib.safeTransfer(token, beneficiary(), amount);
        }
    }

    function releasable() public view virtual returns (uint256) {
        uint256 daoTokenIncrease = IERC20(_daoToken).totalSupply() - _lastUpdatedDaoTokenIncrease - _initDaoTokenBalance;
        return daoTokenIncrease * address(this).balance / _totalDaoTokenIssuance;
    }

    function releasable(address token) public view virtual returns (uint256) {
        uint256 daoTokenIncrease =
            IERC20(_daoToken).totalSupply() - _lastUpdatedDaoTokenIncreases[token] - _initDaoTokenBalance;
        return daoTokenIncrease * IERC20(token).balanceOf(address(this)) / _totalDaoTokenIssuance;
    }

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function released() public view virtual returns (uint256) {
        return _released;
    }

    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    function getDaoToken() public view virtual returns (address) {
        return _daoToken;
    }

    function getLastUpdatedDaoTokenIncrease() public view virtual returns (uint256) {
        return _lastUpdatedDaoTokenIncrease;
    }

    function getLastUpdatedDaoTokenIncrease(address token) public view virtual returns (uint256) {
        return _lastUpdatedDaoTokenIncreases[token];
    }

    function getTotalDaoTokenIssuance() public view virtual returns (uint256) {
        return _totalDaoTokenIssuance;
    }

    receive() external payable virtual { }
}

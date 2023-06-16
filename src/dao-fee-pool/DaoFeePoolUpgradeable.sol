// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract DaoFeePoolUpgradeable is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public name;
    bytes32 public constant AUTO_TRANSFER_ROLE = keccak256("AUTO_TRANSFER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, address admin, address autoTransferer) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(AUTO_TRANSFER_ROLE, autoTransferer);
        name = name_;
    }

    function transfer(address token, address payable to, uint256 amount) public nonReentrant returns (bool success) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(AUTO_TRANSFER_ROLE, msg.sender),
            "only admin or auto transfer can call this"
        );

        if (token == address(0)) {
            (bool succ,) = to.call{ value: amount }("");
            require(succ, "transfer eth failed");
            return true;
        }

        IERC20Upgradeable(token).safeTransfer(to, amount);
        return true;
    }

    receive() external payable { }

    function changeAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != newAdmin, "new admin cannot be same as old one");
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC20PermitUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract RoyaltyTokenUpgradeable is AccessControlUpgradeable, ERC20PermitUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address minter,
        address burner
    )
        public
        initializer
    {
        __AccessControl_init();
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(BURNER_ROLE, burner);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "only for minter");
        super._mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "only for burner");
        super._burn(from, amount);
    }

    function changeAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != newAdmin, "new admin cannot be same as old one");
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

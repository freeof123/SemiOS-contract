// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../D4AProtocolWithPermission.sol";

contract TestD4AProtocolWithPermission is D4AProtocolWithPermission {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // function initialize(address _settings) external initializer {
    //     __ReentrancyGuard_init();
    //     settings = ID4ASetting(_settings);
    //     project_num = settings.reserved_slots();
    //     __EIP712_init("D4AProtocolWithPermission", "1");
    // }
}

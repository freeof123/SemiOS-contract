// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error D4A__OnlyAdminCanSpecifyDaoIndex();

error D4A__ProtocolPaused();

error D4A__DaoPaused(bytes32 id);

error D4A__UriNotExist(string uri);

error D4A__UriAlreadyExist(string uri);

error D4A__InvalidMintableRounds();

error D4A__RoyaltyFeeInBpsOutOfRange();

error D4A__InsufficientEther();

error D4A__DaoAlreadyExist(bytes32 daoId);

error D4A__StartRoundAlreadyPassed();

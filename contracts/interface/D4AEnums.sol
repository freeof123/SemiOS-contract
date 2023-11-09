// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum PriceTemplateType {
    EXPONENTIAL_PRICE_VARIATION,
    LINEAR_PRICE_VARIATION
}

enum RewardTemplateType {
    LINEAR_REWARD_ISSUANCE,
    EXPONENTIAL_REWARD_ISSUANCE,
    UNIFORM_DISTRIBUTION_REWARD
}

enum TemplateChoice {
    PRICE,
    REWARD
}

enum DaoTag {
    D4A_DAO,
    BASIC_DAO,
    FUNDING_DAO
}

enum DeployMethod {
    REMOVE,
    REPLACE,
    ADD,
    REMOVE_AND_ADD
}

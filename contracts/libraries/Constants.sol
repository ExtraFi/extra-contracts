// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    uint256 internal constant PERCENT_100 = 10000;
    uint256 internal constant MINIMAL_WITHDRAW_WAIT_TIME = 300;

    uint256 internal constant PROTOCOL_FEE_TYPE_WITHDRAW = 1;
    uint256 internal constant PROTOCOL_FEE_TYPE_LIQUIDATE = 2;
    uint256 internal constant PROTOCOL_FEE_TYPE_COMPOUND = 3;
    uint256 internal constant PROTOCOL_FEE_TYPE_RANGESTOP = 4;
    uint256 internal constant PROTOCOL_FEE_TYPE_BORROWFEE = 5;

    uint16 internal constant VAULT_VERSION_VELO_V1 = 0;
    uint16 internal constant VAULT_VERSION_VELO_V2 = 1;
    uint16 internal constant VAULT_VERSION_UNI_V3 = 2;
    uint16 internal constant VAULT_VERSION_CURVE = 3;
}

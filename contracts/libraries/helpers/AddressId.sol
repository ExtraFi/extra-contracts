// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

library AddressId {
    uint256 constant ADDRESS_ID_WETH9 = 1;
    uint256 constant ADDRESS_ID_UNI_V3_FACTORY = 2;
    uint256 constant ADDRESS_ID_UNI_V3_NONFUNGIBLE_POSITION_MANAGER = 3;
    uint256 constant ADDRESS_ID_UNI_V3_SWAP_ROUTER = 4;
    uint256 constant ADDRESS_ID_VELO_ROUTER = 5;
    uint256 constant ADDRESS_ID_VELO_FACTORY = 6;
    uint256 constant ADDRESS_ID_VAULT_POSITION_MANAGER = 7;
    uint256 constant ADDRESS_ID_SWAP_EXECUTOR_MANAGER = 8;
    uint256 constant ADDRESS_ID_LENDING_POOL = 9;
    uint256 constant ADDRESS_ID_VAULT_FACTORY = 10;
    uint256 constant ADDRESS_ID_TREASURY = 11;
    uint256 constant ADDRESS_ID_VE_TOKEN = 12;

    uint256 constant ADDRESS_ID_VELO_ROUTER_V2 = 13;
    uint256 constant ADDRESS_ID_VELO_FACTORY_V2 = 14;

    uint256 constant ADDRESS_ID_VE_REWARD_DISTRIBUTOR = 15;

    uint256 constant ADDRESS_ID_VAULT_DEPLOYER_SELECTOR = 101;
    uint256 constant ADDRESS_ID_VELO_VAULT_INITIALIZER = 102;
    uint256 constant ADDRESS_ID_VELO_VAULT_POSITION_LOGIC = 103;
    uint256 constant ADDRESS_ID_VELO_VAULT_REWARDS_LOGIC = 104;
    uint256 constant ADDRESS_ID_VELO_VAULT_OWNER_ACTIONS = 105;
    uint256 constant ADDRESS_ID_VELO_SWAP_PATH_MANAGER = 106;

    uint256 constant ADDRESS_ID_CHAINLINK_ORACLE = 107;

    // 1000 -> 1999 Vault Related Address
    uint256 constant ADDRESS_ID_VAULT_DEPLOYER = 1001;
    uint256 constant ADDRESS_ID_VAULT_INITIALIZER = 1002;
    uint256 constant ADDRESS_ID_VAULT_POSITION_LOGIC = 1003;
    uint256 constant ADDRESS_ID_VAULT_REWARDS_LOGIC = 1004;
    uint256 constant ADDRESS_ID_VAULT_OWNER_ACTIONS = 1005;

    function versionedAddressId(
        uint16 vaultVersion,
        uint256 addressId
    ) internal pure returns (uint256) {
        if (addressId < 1000) {
            return addressId;
        }

        return (uint256(vaultVersion) << 128) | addressId;
    }
}

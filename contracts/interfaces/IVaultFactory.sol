// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IVaultFactory {
    event NewVault(
        address indexed token0,
        address indexed token1,
        bool stable,
        address vaultAddress,
        uint256 indexed vaultId
    );

    function vaults(uint256 vaultId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IAddressRegistry.sol";

library VaultDeployerSelector {
    function deploy(
        address provider,
        uint256 vaultId,
        bytes calldata params
    ) external returns (address) {
        (uint16 version, bytes memory deployParams) = abi.decode(
            params,
            (uint16, bytes)
        );

        address libraryAddress = IAddressRegistry(provider).getAddress(
            AddressId.versionedAddressId(
                version,
                AddressId.ADDRESS_ID_VAULT_DEPLOYER
            )
        );

        require(libraryAddress != address(0), "Library address is not set");

        bytes4 selector = bytes4(
            keccak256(bytes("deploy(address,uint256,bytes)"))
        );

        (bool success, bytes memory result) = libraryAddress.delegatecall(
            abi.encodeWithSelector(selector, provider, vaultId, deployParams)
        );

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        address vaultAddress = abi.decode(result, (address));

        return vaultAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./external/openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IVeloVault.sol";
import "./libraries/helpers/Errors.sol";

contract VaultFactory is Ownable, IVaultFactory {
    mapping(uint256 => address) public vaults;
    uint256 public nextVaultID;

    // global address provider
    address public immutable addressRegistry;

    constructor(address _addressRegistry) {
        require(_addressRegistry != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        addressRegistry = _addressRegistry;
        nextVaultID = 1;
    }

    /// @notice  New a Vault which contains the amm pool's info and the debt positions
    /// Each vault has a debt position that is shared by all the vault positions of this vault
    /// @return vaultId The ID of vault
    function newVault(
        bytes calldata params
    ) external onlyOwner returns (uint256 vaultId) {
        vaultId = nextVaultID;
        nextVaultID = nextVaultID + 1;

        address libraryAddress = IAddressRegistry(addressRegistry).getAddress(
            AddressId.ADDRESS_ID_VAULT_DEPLOYER_SELECTOR
        );
        require(libraryAddress != address(0), "Library address is not set");

        bytes4 selector = bytes4(
            keccak256(bytes("deploy(address,uint256,bytes)"))
        );
        (bool success, bytes memory result) = libraryAddress.delegatecall(
            abi.encodeWithSelector(selector, addressRegistry, vaultId, params)
        );

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        address vaultAddress = abi.decode(result, (address));

        IVeloVault vault = IVeloVault(vaultAddress);

        vaults[vaultId] = vaultAddress;
        emit NewVault(
            vault.token0(),
            vault.token1(),
            vault.stable(),
            vaultAddress,
            vaultId
        );
    }
}

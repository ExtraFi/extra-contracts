// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/helpers/AddressId.sol";

interface IAddressRegistry {
    event SetAddress(
        address indexed setter,
        uint256 indexed id,
        address newAddress
    );

    function getAddress(uint256 id) external view returns (address);
}

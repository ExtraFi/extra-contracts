// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ReserveKey {
    /// @dev Returns the key of the reserve in the lending pool
    function compute(
        address reserve,
        address eTokenAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(reserve, eTokenAddress));
    }
}

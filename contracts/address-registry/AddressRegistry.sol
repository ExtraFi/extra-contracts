// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAddressRegistry.sol";

contract AddressRegistry is IAddressRegistry, Ownable {
    mapping(uint256 => address) libraryAndContractAddresses;

    constructor(address _weth9) {
        setAddress(AddressId.ADDRESS_ID_WETH9, _weth9);
    }

    function setAddress(uint256 id, address _addr) public onlyOwner {
        libraryAndContractAddresses[id] = _addr;
        emit SetAddress(_msgSender(), id, _addr);
    }

    function getAddress(uint256 id) external view returns (address) {
        return libraryAndContractAddresses[id];
    }
}

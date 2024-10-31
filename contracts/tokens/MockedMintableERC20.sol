// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockedMintableERC20 is ERC20 {
    constructor(
      string memory _name,
      string memory _symbol
    )ERC20(_name, _symbol) {}

    function mint(address user, uint256 amount) external  {
        _mint(user, amount);
    }
}
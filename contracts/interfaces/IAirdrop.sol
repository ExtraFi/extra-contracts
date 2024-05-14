// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAirdrop {
    event AirdropSet(uint256 accountCount, uint256 totalAmount);

    event AirdropClaimable(address indexed user, uint256 amount);

    event AirdropClaimed(address indexed user, uint256 amount);

    /// @notice leftover tokens after claiming period have been swept
    event Swept(uint256 amount);
    /// @notice new address set to receive unclaimed tokens
    event SweepReceiverSet(address indexed newSweepReceiver);
    /// @notice Tokens withdrawn
    event Withdrawal(address indexed recipient, uint256 amount);

    function airdropToken() external view returns (IERC20);

    function balanceOf(address) external view returns (uint256);

    function claim() external;
}

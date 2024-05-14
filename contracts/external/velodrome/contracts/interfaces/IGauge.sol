// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IGauge {
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint amount
    );

    function earned(
        address token,
        address account
    ) external view returns (uint);

    function stake() external view returns (address);

    function tokenIds(address) external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function rewardsListLength() external view returns (uint);

    function isReward(address) external view returns (bool);

    function depositAll(uint tokenId) external;

    function deposit(uint amount, uint tokenId) external;

    function withdrawAll() external;

    function withdraw(uint amount) external;

    function notifyRewardAmount(address token, uint amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint claimed0, uint claimed1);

    function left(address token) external view returns (uint);

    function isForPair() external view returns (bool);

    function rewardRate(address) external view returns (uint256);

    function periodFinish(address) external view returns (uint256);

    function rewards(uint) external view returns (address);
}

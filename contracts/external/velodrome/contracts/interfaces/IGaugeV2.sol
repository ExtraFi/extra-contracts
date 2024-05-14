// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IGaugeV2 {
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint amount
    );

    function voter() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint);

    function stake() external view returns (address);

    function tokenIds(address) external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function rewardsListLength() external view returns (uint);

    function isReward(address) external view returns (bool);

    function depositAll(uint tokenId) external;

    function deposit(uint amount) external;

    function withdrawAll() external;

    function withdraw(uint amount) external;

    function notifyRewardAmount(uint amount) external;

    function getReward(address account) external;

    function claimFees() external returns (uint claimed0, uint claimed1);

    function left(address token) external view returns (uint);

    function isForPair() external view returns (bool);

    function rewardRate() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewards(address) external view returns (uint256);
}

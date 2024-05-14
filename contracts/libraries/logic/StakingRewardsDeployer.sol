// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lendingpool/StakingRewards.sol";

library StakingRewardsDeployer {
    function deploy(address stakingToken) external returns (address) {
        address stakingAddress = address(new StakingRewards(stakingToken));

        return stakingAddress;
    }
}

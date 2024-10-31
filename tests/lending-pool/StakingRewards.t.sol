pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../../contracts/tokens/MockedMintableERC20.sol";
import "../../contracts/lendingpool/StakingRewards.sol";

contract StakingRewardsTest is Test {
  
  StakingRewards stakingContract;
  MockedMintableERC20 stakedToken;

  address lendingPool;
  address owner;

  function setUp() public {
      stakedToken = new MockedMintableERC20("E_TOKEN", "E_TOKEN");

      owner = makeAddr("STAKING_REWARDS_OWNER");

      stakingContract = new StakingRewards(address(stakedToken));

      lendingPool = stakingContract.lendingPool();

      stakingContract.transferOwnership(owner);
  }

  function testFail_setRewardsByOthers() public {
    address other = makeAddr("Alice");
    vm.startPrank(other);

    MockedMintableERC20 rewardToken = new MockedMintableERC20("Rewards", "Rewards");

    console2.log("owner", owner);
    console2.log("caller", other);

    uint256 startTime = 1672502400;
    uint256 endTime = 1704038400;
    uint256 totalRewards = 1e24;
    
    vm.expectRevert(bytes("Ownable: caller is not the owner !"));

    stakingContract.setReward(
        address(rewardToken),
        startTime,
        endTime,
        totalRewards
    );

    vm.stopPrank();
  }

  function test_setRewardsByOwner() public {
    vm.startPrank(owner);

    MockedMintableERC20 rewardToken = new MockedMintableERC20("Rewards", "Rewards");

    console2.log("owner", owner);

    uint256 startTime = 1672502400;
    uint256 endTime = 1704038400;
    uint256 totalRewards = 1e24;

    rewardToken.mint(owner, totalRewards);

    rewardToken.approve(
      address(stakingContract),
      totalRewards
    );

    stakingContract.setReward(
        address(rewardToken),
        startTime,
        endTime,
        totalRewards
    );

    (
        uint256 _startTime,
        uint256 _endTime,
        uint256 rewardRate,
        , 
    ) = stakingContract.rewardData(address(rewardToken));

    assertEq(startTime, _startTime);
    assertEq(endTime, _endTime);
    assertEq(rewardRate, totalRewards / (_endTime - _startTime));


    vm.stopPrank();
  }

  function test_stake() public {
    address alice = makeAddr("Alice");

    vm.startPrank(alice);

    uint256 amount = 1e20;

    stakedToken.mint(alice, amount);
    stakedToken.approve(address(stakingContract), amount);

    stakingContract.stake(
      amount,
      alice
    );

    assertEq(stakingContract.balanceOf(alice), amount);
    assertEq(stakedToken.balanceOf(address(stakingContract)), amount);
    assertEq(stakedToken.balanceOf(alice), 0);

    vm.stopPrank();
  }

  function test_unstake() public {
    address alice = makeAddr("Alice");
    vm.startPrank(alice);

    uint256 amount = 1e20;

    // mint token and stake to stakingContract
    stakedToken.mint(alice, amount);
    stakedToken.approve(address(stakingContract), amount);

    stakingContract.stake(
      amount,
      alice
    );

    assertEq(stakingContract.balanceOf(alice), amount);
    assertEq(stakedToken.balanceOf(address(stakingContract)), amount);
    assertEq(stakedToken.balanceOf(alice), 0);

    // withdraw staked token
    stakingContract.withdraw(amount, alice);
    assertEq(stakingContract.balanceOf(alice), 0);
    assertEq(stakedToken.balanceOf(address(stakingContract)), 0);
    assertEq(stakedToken.balanceOf(alice), amount);

    vm.stopPrank();
  }

  function test_rewards() public {
    // alice and bob stake
    address alice = makeAddr("Alice");
    address bob = makeAddr("Bob");

    uint256 stakeTime = 1672502300;
    vm.warp(stakeTime);
    stakeByUser(alice, 1e20);
    stakeByUser(bob, 4e20);
    assertEq(stakingContract.balanceOf(alice), 1e20);
    assertEq(stakingContract.balanceOf(bob), 4e20);

    // set rewards
    uint256 startTime = 1672502400;
    uint256 endTime = 1704038400;
    uint256 totalRewards = 1e24;

    uint256 rewardRate = 1e24 / (endTime - startTime);

    vm.startPrank(owner);
    vm.warp(startTime);

    MockedMintableERC20 rewardToken = new MockedMintableERC20("Rewards", "Rewards");

    rewardToken.mint(owner, totalRewards);
    rewardToken.approve(
      address(stakingContract),
      totalRewards
    );
    stakingContract.setReward(
        address(rewardToken),
        startTime,
        endTime,
        totalRewards
    );
    vm.stopPrank();

    // cliam after a period of time
    vm.warp(endTime);

    vm.startPrank(alice);
    stakingContract.claim();
    assertEq(
      rewardToken.balanceOf(alice),
      rewardRate * (endTime - startTime) * 1e20  / 5e20 
    );
    vm.stopPrank();

    vm.startPrank(bob);
    stakingContract.claim();
    assertEq(
      rewardToken.balanceOf(bob),
      rewardRate * (endTime - startTime) * 4e20  / 5e20 
    );
    vm.stopPrank();
  }

  function stakeByUser(address user, uint256 amount) internal {
    vm.startPrank(user);

    // mint token and stake to stakingContract
    stakedToken.mint(user, amount);
    stakedToken.approve(address(stakingContract), amount);

    stakingContract.stake(
      amount,
      user
    );

    assertEq(stakingContract.balanceOf(user), amount);

    vm.stopPrank();
  }
}
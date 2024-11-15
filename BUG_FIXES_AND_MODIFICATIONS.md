# On-Chain vs. Repository Contract Code Comparison: Bug Fixes and Modifications

This document outlines known bugs in the mainnet code, their impacts, and the actions taken to mitigate them. Since mainnet contracts are non-upgradable, some fixes were applied only in the repository code. Comparisons and descriptions of these differences are provided below.

## Bugs and Fixes

### eToken Inflation Vulnerability

In the lending pool’s eToken, using logic inspired by Compound’s cToken, the exchange rate between eToken and underlying assets is calculated as exchangeRate = balance / eToken.supply(). Under this logic, the first depositor can deposit a minimal amount, such as 1 wei, to receive 1 wei of eToken. If they then transfer a large sum of liquidity directly to the eToken contract address, this inflates the eToken rate, allowing their initial 1 wei of eToken to redeem the full liquidity amount. Due to Solidity’s integer division (9000 / 10000 = 0), this bug can lead to eToken issuance issues. An attacker could exploit this by front-running the first user in an empty pool.

#### Mainnet Mitigation

To address this on mainnet without modifying contracts, we employ batched transactions to initialize the pool and make the first deposit in a single transaction. Additionally, the first 10,000 eTokens are sent to 0x0000…dead, making them permanently unredeemable. This prevents inflation attacks.

#### Code Fix

In the repository, we burn the first 1,000 eTokens upon the initial deposit.

```solidity
if (IExtraInterestBearingToken(reserve.eTokenAddress).totalSupply() == 0) {
    IExtraInterestBearingToken(reserve.eTokenAddress).mint(
        DEAD_ADDRESS,
        MINIMUM_ETOKEN_AMOUNT
    );
    eTokenAmount -= MINIMUM_ETOKEN_AMOUNT;
}
```

### Insufficient endTime Validation in StakingRewards.setReward()

In `StakingRewards.setReward()`, the `endTime` parameter should be validated to ensure it is greater than block.timestamp, preventing rewards calculation from failing unexpectedly.

```solidity
function setReward(
    address rewardToken,
    uint256 startTime,
    uint256 endTime,
    uint256 totalRewards
) public onlyOwner nonReentrant updateReward(address(0)) {
    require(startTime < endTime, "start must lt end");
    require(rewardData[rewardToken].endTime < block.timestamp, "not end");
}
```

#### Mainnet Mitigation

Since this function can only be called by the owner’s multisig wallet, it cannot be exploited by others. This parameter is verified during the multisig transaction setup and requires approval from at least three signers.

#### Code Fix

```solidity
function setReward(
    address rewardToken,
    uint256 startTime,
    uint256 endTime,
    uint256 totalRewards
) public onlyOwner nonReentrant updateReward(address(0)) {
    require(startTime < endTime, "start must lt end");
    require(block.timestamp < endTime, "!end");
}
```

### Credit Logic Bug in LendingPool.repay()

In the mainnet code, an issue exists in repay() where credit is incremented by the input amount, instead of the actual repaid debt. This can lead to unlimited credit after a single call if the repayment amount exceeds the debt.

```solidity
{
  uint256 credit = credits[debtPosition.reserveId][_msgSender()];
  credits[debtPosition.reserveId][_msgSender()] = credit.add(amount);

  if (amount > debtPosition.borrowed) {
      amount = debtPosition.borrowed;
  }
  reserve.totalBorrows = reserve.totalBorrows.sub(amount);
  debtPosition.borrowed = debtPosition.borrowed.sub(amount);
}
```

#### Mainnet Mitigation

As `LendingPool.repay()` can only be called by whitelisted vault contract addresses, it is secure from external exploitation.

#### Code Fix

Credits are updated based on the actual repaid amount.

```solidity
reserve.totalBorrows = reserve.totalBorrows.sub(amount);
debtPosition.borrowed = debtPosition.borrowed.sub(amount);

uint256 credit = credits[debtPosition.reserveId][_msgSender()];
credits[debtPosition.reserveId][_msgSender()] = credit.add(amount);
```

### Reward Claim Blocking in StakingRewards.claim()

In `StakingRewards.claim()`, a failed reward token transfer prevents the claiming of all rewards in a single transaction.

#### Mainnet Mitigation

Reward tokens are only added by the owner’s multisig wallet through `setReward()`. The team carefully verifies each reward token’s transferability to prevent issues.

#### Code Fix

A function was added to allow claiming specific reward tokens: `claim(address[] calldata rewards)`

### Front-Running Risk in StakingRewards.setReward()

In `StakingRewards.setReward()`, rewards are distributed from startTime to endTime. If startTime has already passed, rewards for that duration are distributed to current liquidity holders. Attackers can deposit significant liquidity just before setReward() is called to capture rewards and withdraw them soon after.

#### Mainnet Mitigation

When executing setReward(), ensure it occurs before startTime whenever possible. If startTime is in the past, the effect on rewards is minor.

#### Code Fix

The startTime is set to max(block.timestamp, startTime) to prevent exploitation.


### Cannot repay debts when reserve.totalBorrows < debtPosition.borrowed, which can occur due to rounding errors

In the LendingPool, debt calculations rely heavily on an index variable, which starts at 1e18 and incrementally grows based on accrued interest. Whenever the pool is updated, both the pool’s index and totalDebt adjust according to the interest rate and elapsed time.

Each debtPosition contains its own index and debt values, which only update when the position itself is modified. The updated debt for a position can be calculated using the difference between the position’s index and the reserve’s index.

In theory, the pool’s totalDebt should match the sum of all position debts. However, because each calculation uses integer arithmetic, rounding errors can occur. With each pool update, small rounding inaccuracies accumulate in the pool’s totalDebt, while debtPosition values, updated less frequently, don’t adjust at the same rate. Over time and with repeated interactions, this may cause the pool’s totalDebt to become slightly less than the combined debt of all positions.

#### Mainnet Mitigation

Due to the non-upgradeable nature of the LendingPool contract, additional logic has been incorporated into the Vault contract to ensure that repaid debt does not exceed the pool’s totalDebt. 

#### Code Fix

```solidity
{
  if (amount > debtPosition.borrowed) {
    amount = debtPosition.borrowed;
  }

  if (amount > reserve.totalBorrows) {
    amount = reserve.totalBorrows;
  }
}
```


### reserve.lastUpdateTimestamp hasn't been correctly updated while first borrow occurs

`reserve.lastUpdateTimestamp` is crucial for calculating interest on borrowed liquidity. It should update whenever there's a pool update. However, in the contract, it only updates when `reserve.totalBorrows > 0`. Consequently, it doesn't update during the first borrow because totalBorrows = 0 prior to the first borrow. This results in interest for the first borrower's debt being calculated from the reserve's initialization time to the current time, rather than from the time of borrowing to the current time. As a result, the initial borrower's debt is larger than it should be.

```solidity
function _updateIndexes(DataTypes.ReserveData storage reserve) internal {
    uint256 newBorrowingIndex = reserve.borrowingIndex;
    uint256 newTotalBorrows = reserve.totalBorrows;

    if (reserve.totalBorrows > 0) {
        newBorrowingIndex = latestBorrowingIndex(reserve);
        newTotalBorrows = newBorrowingIndex.mul(reserve.totalBorrows).div(
            reserve.borrowingIndex
        );

        require(
            newBorrowingIndex <= type(uint128).max,
            Errors.LP_BORROW_INDEX_OVERFLOW
        );

        reserve.borrowingIndex = newBorrowingIndex;
        reserve.totalBorrows = newTotalBorrows;
        reserve.lastUpdateTimestamp = uint128(block.timestamp);
    }
}
```

#### Mainnet Mitigation

Team borrowing a small amount when listing a lending pool.


#### Code Fix

```solidity
function _updateIndexes(DataTypes.ReserveData storage reserve) internal {
    uint256 newBorrowingIndex = reserve.borrowingIndex;
    uint256 newTotalBorrows = reserve.totalBorrows;

    if (reserve.totalBorrows > 0) {
        newBorrowingIndex = latestBorrowingIndex(reserve);
        newTotalBorrows = newBorrowingIndex.mul(reserve.totalBorrows).div(
            reserve.borrowingIndex
        );

        require(
            newBorrowingIndex <= type(uint128).max,
            Errors.LP_BORROW_INDEX_OVERFLOW
        );

        reserve.borrowingIndex = newBorrowingIndex;
        reserve.totalBorrows = newTotalBorrows;
    }
    reserve.lastUpdateTimestamp = uint128(block.timestamp);
}
```


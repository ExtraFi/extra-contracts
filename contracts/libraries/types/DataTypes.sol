// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
    struct DebtPositionData {
        uint256 reserveId;
        address owner;
        uint256 borrowed;
        uint256 borrowedIndex;
    }

    struct VaultPositionData {
        // manager of the position, who can adjust the position
        address manager;
        // tokenId of the v3 NFT position
        uint256 v3TokenId;
        // The debt positionId for token0
        uint256 debtPositionId0;
        // The debt share for token0
        uint256 debtShare0;
        // The debt positionId for token1
        uint256 debtPositionId1;
        // The debt share for token1
        uint256 debtShare1;
        // Total shares of this position
        uint256 totalShares;
    }

    // Interest Rate Config
    // The utilization rate and borrowing rate are expressed in RAY
    // utilizationB must gt utilizationA
    struct InterestRateConfig {
        // The utilization rate a, the end of the first slope on interest rate curve
        uint128 utilizationA;
        // The borrowing rate at utilization_rate_a
        uint128 borrowingRateA;
        // The utilization rate a, the end of the first slope on interest rate curve
        uint128 utilizationB;
        // The borrowing rate at utilization_rate_b
        uint128 borrowingRateB;
        // the max borrowing rate while the utilization is 100%
        uint128 maxBorrowingRate;
    }

    struct ReserveData {
        // variable borrow index.
        uint256 borrowingIndex;
        // the current borrow rate.
        uint256 currentBorrowingRate;
        // the total borrows of the reserve at a variable rate. Expressed in the currency decimals
        uint256 totalBorrows;
        // underlying token address
        address underlyingTokenAddress;
        // eToken address
        address eTokenAddress;
        // staking address
        address stakingAddress;
        // the capacity of the reserve pool
        uint256 reserveCapacity;
        // borrowing rate config
        InterestRateConfig borrowingRateConfig;
        // the id of the reserve. Represents the position in the list of the reserves
        uint256 id;
        uint128 lastUpdateTimestamp;
        // reserve fee charged, percent of the borrowing interest that is put into the treasury.
        uint16 reserveFeeRate;
        Flags flags;
    }

    struct Flags {
        bool isActive; // set to 1 if the reserve is properly configured
        bool frozen; // set to 1 if reserve is frozen, only allows repays and withdraws, but not deposits or new borrowings
        bool borrowingEnabled; // set to 1 if borrowing is enabled, allow borrowing from this pool
    }
}

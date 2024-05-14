// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

library VaultTypes {
    struct VeloVaultStorage {
        VeloVaultState state;
        mapping(uint256 => VeloPosition) positions;
        uint256 nextPositionId;
        address[] rewardTokens;
        address addressProvider;
        address veloFactory;
        address veloRouter;
        address swapPathManager;
        address lendingPool;
        address vaultPositionManager;
        address WETH9;
        address veToken;
    }

    struct VeloPositionValue {
        // manager of the position, who can adjust the position
        address manager;
        bool isActive;
        bool enableRangeStop;
        // timestamp when open
        uint64 openedAt;
        // timestamp now
        uint64 current;
        // token0Principal is the original invested token0
        uint256 token0Principal;
        // token1Principal is the original invested token1
        uint256 token1Principal;
        // liquidityPrincipal is the original liquidity user added to the pool
        uint256 liquidityPrincipal;
        // left token0 not added to the liquidity
        uint256 token0Left;
        // left Token1 not added to the liquidity
        uint256 token1Left;
        // left token0 in liquidity
        uint256 token0InLiquidity;
        // left Token1 not added to the liquidity
        uint256 token1InLiquidity;
        // The lp amount
        uint256 liquidity;
        // The debt share of debtPosition0 in the vault
        uint256 debt0;
        // The debt share for debtPosition1 in the vault
        uint256 debt1;
        // The borrowingIndex of debt0 in lendingPool
        uint256 borrowingIndex0;
        // The borrowingIndex of debt1 in lendingPool
        uint256 borrowingIndex1;
        // range stop config
        uint256 minPriceOfRangeStop;
        uint256 maxPriceOfRangeStop;
    }

    struct VeloPosition {
        // manager of the position, who can adjust the position
        address manager;
        bool isActive;
        bool enableRangeStop;
        // timestamp when open
        uint64 openedAt;
        // token0Principal is the original invested token0
        uint256 token0Principal;
        // token1Principal is the original invested token1
        uint256 token1Principal;
        // liquidityPrincipal is the original liquidity user added to the pool
        uint256 liquidityPrincipal;
        // left token0 not added to the liquidity
        uint256 token0Left;
        // left Token1 not added to the liquidity
        uint256 token1Left;
        // The lp shares in the vault
        uint256 lpShares;
        // The debt share of debtPosition0 in the vault
        uint256 debtShare0;
        // The debt share for debtPosition1 in the vault
        uint256 debtShare1;
        // range stop config
        uint256 minPriceOfRangeStop;
        uint256 maxPriceOfRangeStop;
        uint256 lastInvestTime;
    }

    struct VeloVaultState {
        address gauge;
        address pair;
        address token0;
        address token1;
        bool stable;
        // If the vault is paused, new or close positions would be rejected by the contract.
        bool paused;
        // If the vault is frozen, only new position action is rejected, the close is normal.
        bool frozen;
        // Only if this feature is true, users of the vault can borrow tokens from lending pool.
        bool borrowingEnabled;
        // liquidate with TWAP
        bool liquidateWithTWAP;
        // max leverage when open a position
        // the value has with a multiplier of 100
        // 1x -> 1 * 100
        // 2x -> 2 * 100
        uint16 maxLeverage;
        // premium leverage for a position of users who have specific veToken's voting power
        uint16 premiumMaxLeverage;
        uint16 maxPriceDiff;
        // The debt ratio trigger liquidation
        // When a position's debt ratio goes out of liquidateDebtRatio
        // the position can be liquidated
        uint16 liquidateDebtRatio;
        uint16 borrowFeeRate;
        uint16 compoundFeeRate;
        uint16 liquidateFeeRate;
        uint16 rangeStopFeeRate;
        uint16 protocolFeeRate;
        // the minimal voting power reqruired to use premium functions
        uint256 premiumRequirement;
        // Protocol Fee
        uint256 protocolFee0Accumulated;
        uint256 protocolFee1Accumulated;
        // minimal invest value
        uint256 minInvestValue;
        uint256 minSwapAmount0;
        uint256 minSwapAmount1;
        // total lp
        uint256 totalLp;
        uint256 totalLpShares;
        // the utilization of the lending reserve pool trigger premium check
        uint256 premiumUtilizationOfReserve0;
        // debt limit of token0
        uint256 debtLimit0;
        // debt positionId of token0
        uint256 debtPositionId0;
        // debt total_shares
        uint256 debtTotalShares0;
        // the utilization of the lending reserve pool trigger premium check
        uint256 premiumUtilizationOfReserve1;
        // debt limit of token1
        uint256 debtLimit1;
        // debt positionId of token1
        uint256 debtPositionId1;
        // debt total_shares
        uint256 debtTotalShares1;
    }
}

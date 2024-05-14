// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../external/velodrome/contracts/interfaces/IRouter.sol";
import "../libraries/types/VaultTypes.sol";

interface IVeloVaultPositionManager {
    /// @notice New a vaultPosition
    /// @param vaultId The id of the vault
    /// @param manager The manager of the position, usually the caller
    /// @param vaultPositionId The id of the newed position
    event NewVaultPosition(
        uint256 indexed vaultId,
        uint256 indexed vaultPositionId,
        address indexed manager
    );

    /// @notice Invest to a position
    /// @param vaultId The id of the vault
    /// @param vaultPositionId The id of the new vaultPosition
    /// @param manager The manager of the vaultPosition, usually the caller
    /// @param amount0Invest The amount of token0 user wants to transfer
    /// @param amount1Invest The amount of token1 user wants to transfer
    /// @param amount0Borrow The amount of token0 user wants to borrow
    /// @param amount1Borrow The amount of token1 user wants to borrow
    /// @param liquidity The amount of lp tokens added to the pool
    event InvestToVaultPosition(
        uint256 indexed vaultId,
        uint256 indexed vaultPositionId,
        address indexed manager,
        uint256 amount0Invest,
        uint256 amount1Invest,
        uint256 amount0Borrow,
        uint256 amount1Borrow,
        uint256 liquidity
    );

    /// @notice Close a position partially
    /// @param vaultId The id of the vault
    /// @param vaultPositionId The id of the vaultPosition
    /// @param manager The manager of the vaultPosition
    /// @param percent The percentage of the vault user want to close
    /// @param amount0Received The amount of token0 user received after close
    /// @param amount1Received The amount of token1 user received after close
    /// @param amount0Repaid The amount of token0 user repaid when close
    /// @param amount1Repaid The amount of token1 user repaid when close
    event CloseVaultPositionPartially(
        uint256 indexed vaultId,
        uint256 indexed vaultPositionId,
        address indexed manager,
        uint16 percent,
        uint256 amount0Received,
        uint256 amount1Received,
        uint256 amount0Repaid,
        uint256 amount1Repaid
    );

    /// @notice Close a position which is outof price range
    /// @param vaultId The id of the vault
    /// @param vaultPositionId The id of the vaultPosition
    /// @param manager The manager of the vaultPosition
    /// @param caller The caller initiate range stop
    /// @param percent The percentage of the vault user want to close
    /// @param amount0Received The amount of token0 user received after close
    /// @param amount1Received The amount of token1 user received after close
    /// @param fee0 The caller received
    /// @param fee1 The caller received
    event CloseOutOfRangePosition(
        uint256 indexed vaultId,
        uint256 indexed vaultPositionId,
        address indexed manager,
        address caller,
        uint16 percent,
        uint64 timestamp,
        uint256 price,
        uint256 amount0Received,
        uint256 amount1Received,
        uint256 fee0,
        uint256 fee1
    );

    /// @notice Liquidate a position partially
    /// @param vaultId The id of the vault
    /// @param vaultPositionId The id of the vaultPosition
    /// @param manager The manager of the vaultPosition
    /// @param liquidator The caller of the function
    /// @param percent The percentage of the vault user want to liquidate
    /// @param amount0Left The amount of token0 transferred to the position's manager after close
    /// @param amount1Left The amount of token1 transferred to the position's manager after close
    /// @param liquidateFee0 The amount of token0 for liquidation bonus
    /// @param liquidateFee1 The amount of token1 for liquidation bonus
    event LiquidateVaultPositionPartially(
        uint256 indexed vaultId,
        uint256 indexed vaultPositionId,
        address indexed manager,
        address liquidator,
        uint16 percent,
        uint64 timestamp,
        uint256 price,
        uint256 debtValueOfPosition,
        uint256 liquidityValueOfPosition,
        uint256 amount0Left,
        uint256 amount1Left,
        uint256 liquidateFee0,
        uint256 liquidateFee1
    );

    /// @notice Liquidate a position partially
    /// @param vaultId The id of the vault
    /// @param vaultPositionId The id of the vaultPosition
    /// @param manager The manager of the vaultPosition
    /// @param caller The initiator of the repay action
    /// @param amount0Repaid The amount of token0 repaid
    /// @param amount1Repaid The amount of token1 repaid
    event ExactRepay(
        uint256 indexed vaultId,
        uint256 indexed vaultPositionId,
        address indexed manager,
        address caller,
        uint256 amount0Repaid,
        uint256 amount1Repaid
    );

    /// @notice InvestEarnedFeeToLiquidity
    /// @param vaultId The id of the vault
    /// @param caller The initiator of the repay action
    /// @param liquidityAdded The liquidity amount added by adding rewards to the pool
    /// @param fee0 The fee in token0
    /// @param fee1 The fee in token1
    /// @param rewards The rewards claimed
    event InvestEarnedFeeToLiquidity(
        uint256 indexed vaultId,
        address indexed caller,
        uint256 liquidityAdded,
        uint256 fee0,
        uint256 fee1,
        uint256[] rewards
    );

    event FeePaid(
        uint256 indexed vaultId,
        address indexed asset,
        uint256 indexed feeType,
        uint256 amount
    );

    function getVaultPosition(
        uint256 vaultId,
        uint256 vaultPositionId
    ) external view returns (VaultTypes.VeloPositionValue memory state);

    function getVault(
        uint256 vaultId
    ) external view returns (VaultTypes.VeloVaultState memory);

    struct PayToVaultCallbackParams {
        uint256 vaultId;
        uint256 amount0;
        uint256 amount1;
        address payer;
    }

    /// @notice Callback functions called by the vault to pay tokens to the vault contract.
    /// The caller to this function must be the vault contract
    function payToVaultCallback(
        PayToVaultCallbackParams calldata params
    ) external;

    /// @notice Callback functions called by the vault to pay fees to treasury.
    /// The caller to this function must be the vault contract
    function payFeeToTreasuryCallback(
        uint256 vaultId,
        address asset,
        uint256 amount,
        uint256 feeType
    ) external;

    /// @notice The param struct used in function newOrInvestToVaultPosition(param)
    struct NewOrInvestToVaultPositionParams {
        // vaultId
        uint256 vaultId;
        // The vaultPositionId of the vaultPosition to invest
        // 0  if open a new vaultPosition
        uint256 vaultPositionId;
        // The amount of token0 user want to invest
        uint256 amount0Invest;
        // The amount of token0 user want to borrow
        uint256 amount0Borrow;
        // The amount of token1 user want to invest
        uint256 amount1Invest;
        // The amount of token1 user want to borrow
        uint256 amount1Borrow;
        // The minimal amount of token0 should be added to the liquidity
        // This value will be used when call mint() or addLiquidity() of AMM pool
        uint256 amount0Min;
        // The minimal amount of token1 should be added to the liquidity
        // This value will be used when call mint() or addLiquidity() of AMM pool
        uint256 amount1Min;
        // The deadline of the tx
        uint256 deadline;
        // The swapExecutor to swap tokens
        uint256 swapExecutorId;
        // The swap path to swap tokens
        bytes swapPath;
    }

    /// @notice Open a new vaultPosition or invest to a existed vault position
    /// @param params The parameters necessary, encoded as `NewOrInvestToVaultPositionParams` in calldata
    function newOrInvestToVaultPosition(
        NewOrInvestToVaultPositionParams calldata params
    ) external payable;

    /// @notice The param struct used in function closeVaultPositionPartially(param)
    struct CloseVaultPositionPartiallyParams {
        // vaultId
        uint256 vaultId;
        // The Id of vaultPosition to be closed
        uint256 vaultPositionId;
        // The percentage of the entire position to close
        uint16 percent;
        // The receiver of the left tokens when close then position
        // Or the fee receiver when used in `closeOutOfRangePosition`
        address receiver;
        bool receiveNativeETH;
        // The receiveType of the left tokens
        // 0: only receive token0, swap all left token1 to token0
        // 1: only receive token1, swap all left token0 to token1
        // 2: receive tokens according to minimal swap rule
        uint8 receiveType;
        // The minimal token0 receive after remove the liquidity, will be used when call removeLiquidity() of AMM
        uint256 minAmount0WhenRemoveLiquidity;
        // The minimal token1 receive after remove the liquidity, will be used when call removeLiquidity() of AMM
        uint256 minAmount1WhenRemoveLiquidity;
        // The deadline of the tx, the tx will be reverted if the _blockTimestamp() > deadline
        uint256 deadline;
        // The swapExecutor to swap tokens
        uint256 swapExecutorId;
        // The swap path to swap tokens
        bytes swapPath;
    }

    /// @notice Close a vaultPosition partially
    /// @param params The parameters necessary, encoded as `CloseVaultPositionPartiallyParams` in calldata
    function closeVaultPositionPartially(
        CloseVaultPositionPartiallyParams calldata params
    ) external;

    /// @notice The param struct used in function closeVaultPositionPartially(param)
    struct LiquidateVaultPositionPartiallyParams {
        // vaultId
        uint256 vaultId;
        // The Id of vaultPosition to be closed
        uint256 vaultPositionId;
        // The percentage of the entire position to close
        uint16 percent;
        // The liquidator's fee receiver
        address receiver;
        bool receiveNativeETH;
        // The receiveType of the left tokens
        // 0: only receive token0, swap all left token1 to token0
        // 1: only receive token1, swap all left token0 to token1
        // 2: receive tokens according to minimal swap rule
        uint8 receiveType;
        // The minimal token0 receive after remove the liquidity, will be used when call removeLiquidity() of AMM
        uint256 minAmount0WhenRemoveLiquidity;
        // The minimal token1 receive after remove the liquidity, will be used when call removeLiquidity() of AMM
        uint256 minAmount1WhenRemoveLiquidity;
        // The deadline of the tx, the tx will be reverted if the _blockTimestamp() > deadline
        uint256 deadline;
        // The maximum amount of token0 to repay debts
        uint256 maxRepay0;
        // The maximum amount of token1 to repay debts
        uint256 maxRepay1;
        // The swapExecutor to swap tokens
        uint256 swapExecutorId;
        // The swap path to swap tokens
        bytes swapPath;
    }

    /// @notice Liquidate a vaultPosition partially
    /// @param params The parameters necessary, encoded as `CloseVaultPositionPartiallyParam` in calldata
    function liquidateVaultPositionPartially(
        LiquidateVaultPositionPartiallyParams calldata params
    ) external payable;

    struct InvestEarnedFeeToLiquidityParam {
        // vaultId
        uint256 vaultId;
        // The compound fee receive
        address compoundFeeReceiver;
        IRouter.route[][] routes;
        bool receiveNativeETH;
        // The deadline of the tx, the tx will be reverted if the _blockTimestamp() > deadline
        uint256 deadline;
    }

    /// @notice Invest the earned fee by the position to liquidity
    /// The manager of the position can call this function with no compound fee charged
    /// If the manager allow others to compound the fee, there will be a small fee charged  as bonus for the caller
    function investEarnedFeeToLiquidity(
        InvestEarnedFeeToLiquidityParam calldata params
    ) external;

    struct ExactRepayParam {
        // vaultId
        uint256 vaultId;
        // The Id of vaultPosition to be closed
        uint256 vaultPositionId;
        // The max amount of token0 to repay
        uint256 amount0ToRepay;
        // The max amount of token1 to repay
        uint256 amount1ToRepay;
        // whether receive nativeETH or WETH when there are un-repaid ETH
        bool receiveNativeETH;
        // The deadline of the tx, the tx will be reverted if the _blockTimestamp() > deadline
        uint256 deadline;
    }

    /// @notice Repay exact value of debts
    function exactRepay(
        ExactRepayParam calldata params
    ) external payable returns (uint256, uint256);

    /// @notice Transfer the position's manager to another wallet
    /// Must be called by the current manager of the posistion
    /// @param vaultId The Id of the vault
    /// @param vaultPositionId The Id of the position
    /// @param newManager The new address of the manager
    function transferManagerOfVaultPosition(
        uint256 vaultId,
        uint256 vaultPositionId,
        address newManager
    ) external;

    /// @notice Set stop-loss price range of the position
    /// Users can set a stop-loss price range for a position only if the position is enabled `RangeStop` feature.
    /// If current price goes out of the stop-loss price range, extraFi's bots will close the position
    /// @param vaultId The Id of the vault
    /// @param vaultPositionId The Id of the position
    /// @param enable The enable status to set
    /// @param minPrice The lower price of the stop-loss price range
    /// @param maxPrice The upper price of the stop-loss price range
    function setRangeStop(
        uint256 vaultId,
        uint256 vaultPositionId,
        bool enable,
        uint256 minPrice,
        uint256 maxPrice
    ) external;
}

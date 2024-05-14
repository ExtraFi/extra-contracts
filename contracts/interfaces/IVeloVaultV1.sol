// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../external/velodrome/contracts/interfaces/IRouter.sol";
import "../libraries/types/VaultTypes.sol";

interface IVeloVaultV1 {
    /// @notice token0 address of the related velo pair
    function token0() external view returns (address);

    /// @notice token1 address of the related velo pair
    function token1() external view returns (address);

    /// @notice stable of the related velo pair
    function stable() external view returns (bool);

    function getVaultState()
        external
        view
        returns (VaultTypes.VeloVaultState memory vault);

    function adminSetVault(bytes calldata params) external;

    function transferManagerTo(
        address caller,
        uint256 positionId,
        address newManager
    ) external;

    function setRangeStop(
        address caller,
        uint256 positionId,
        bool enable,
        uint256 minPrice,
        uint256 maxPrice
    ) external;

    function getPositionValue(
        uint256 vaultPositionId
    ) external view returns (VaultTypes.VeloPositionValue memory positionValue);

    function getPosition(
        uint256 vaultPositionId
    ) external view returns (VaultTypes.VeloPosition memory position);

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

    function newOrInvestToVaultPosition(
        NewOrInvestToVaultPositionParams calldata params,
        address caller
    ) external returns (uint256 positionId, uint256 liquidity);

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

    function closeAndRepayPartially(
        CloseVaultPositionPartiallyParams calldata params,
        address caller
    ) external returns (uint256, uint256, uint256, uint256);

    function closeAndRepayOutOfRangePosition(
        CloseVaultPositionPartiallyParams calldata params
    )
        external
        returns (
            address manager,
            uint256 price,
            uint256 amount0Left,
            uint256 amount1Left,
            uint256 fee0,
            uint256 fee1
        );

    struct LiquidateState {
        address manager;
        uint256 price;
        uint256 amount0Left;
        uint256 amount1Left;
        uint256 amount0Repaid;
        uint256 amount1Repaid;
        uint256 repaidValue;
        uint256 removedLiquidityValue;
        uint256 liquidateFeeValue;
        uint256 equivalentRepaid0;
        uint256 equivalentRepaid1;
        uint256 liquidatorReceive0;
        uint256 liquidatorReceive1;
        uint256 liquidateFee0;
        uint256 liquidateFee1;
    }

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

    function repayAndLiquidatePositionPartially(
        LiquidateVaultPositionPartiallyParams calldata params,
        address caller
    ) external returns (LiquidateState memory);

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

    function exactRepay(
        ExactRepayParam calldata params,
        address caller
    )
        external
        returns (
            address positionMananger,
            uint256 amount0Repaid,
            uint256 amount1Repaid
        );

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

    function claimRewardsAndReInvestToLiquidity(
        InvestEarnedFeeToLiquidityParam calldata params
    )
        external
        returns (
            uint256 liquidity,
            uint256 fee0,
            uint256 fee1,
            uint256[] memory rewards
        );
}

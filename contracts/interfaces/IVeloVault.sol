// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IVeloVaultPositionManager.sol";
import "../libraries/types/VaultTypes.sol";

interface IVeloVault {
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

    function newOrInvestToVaultPosition(
        IVeloVaultPositionManager.NewOrInvestToVaultPositionParams
            calldata params,
        address caller
    ) external returns (uint256 positionId, uint256 liquidity);

    function closeAndRepayPartially(
        IVeloVaultPositionManager.CloseVaultPositionPartiallyParams
            calldata params,
        address caller
    ) external returns (uint256, uint256, uint256, uint256);

    function closeAndRepayOutOfRangePosition(
        IVeloVaultPositionManager.CloseVaultPositionPartiallyParams
            calldata params
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

    function repayAndLiquidatePositionPartially(
        IVeloVaultPositionManager.LiquidateVaultPositionPartiallyParams
            calldata params,
        address caller
    ) external returns (LiquidateState memory);

    function exactRepay(
        IVeloVaultPositionManager.ExactRepayParam calldata params,
        address caller
    )
        external
        returns (
            address positionMananger,
            uint256 amount0Repaid,
            uint256 amount1Repaid
        );

    function claimRewardsAndReInvestToLiquidity(
        IVeloVaultPositionManager.InvestEarnedFeeToLiquidityParam
            calldata params
    )
        external
        returns (
            uint256 liquidity,
            uint256 fee0,
            uint256 fee1,
            uint256[] memory rewards
        );
}

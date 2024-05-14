// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../libraries/types/DataTypes.sol";

interface ILendingPool {
    function utilizationRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function borrowingRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function exchangeRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function totalLiquidityOfReserve(
        uint256 reserveId
    ) external view returns (uint256 totalLiquidity);

    function totalBorrowsOfReserve(
        uint256 reserveId
    ) external view returns (uint256 totalBorrows);

    function getReserveIdOfDebt(uint256 debtId) external view returns (uint256);

    event InitReserve(
        address indexed reserve,
        address indexed eTokenAddress,
        address stakingAddress,
        uint256 id
    );
    /**
     * @dev Emitted on deposit()
     * @param reserveId The id of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the eTokens
     * @param reserveAmount The reserve amount deposited
     * @param eTokenAmount The eToken amount received
     * @param referral The referral code used
     **/
    event Deposited(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 reserveAmount,
        uint256 eTokenAmount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on redeem()
     * @param reserveId The id of the reserve
     * @param user The address initiating the withdrawal, owner of eTokens
     * @param to Address that will receive the underlying tokens
     * @param eTokenAmount The amount of eTokens to redeem
     * @param underlyingTokenAmount The amount of underlying tokens user received after redeem
     **/
    event Redeemed(
        uint256 indexed reserveId,
        address indexed user,
        address indexed to,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    );

    /**
     * @dev Emitted on borrow() when debt needs to be opened
     * @param reserveId The id of the reserve
     * @param contractAddress The address of the contract to initiate this borrow
     * @param onBehalfOf The beneficiary of the borrowing, receiving the tokens in his vaultPosition
     * @param amount The amount borrowed out
     **/
    event Borrow(
        uint256 indexed reserveId,
        address indexed contractAddress,
        address indexed onBehalfOf,
        uint256 amount
    );

    /**
     * @dev Emitted on repay()
     * @param reserveId The id of the reserve
     * @param onBehalfOf The user who repay debts in his vaultPosition
     * @param contractAddress The address of the contract to initiate this repay
     * @param amount The amount repaid
     **/
    event Repay(
        uint256 indexed reserveId,
        address indexed onBehalfOf,
        address indexed contractAddress,
        uint256 amount
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event UnPaused();

    event EnableVaultToBorrow(
        uint256 indexed vaultId,
        address indexed vaultAddress
    );

    event DisableVaultToBorrow(
        uint256 indexed vaultId,
        address indexed vaultAddress
    );

    event SetCreditsOfVault(
        uint256 indexed vaultId,
        address indexed vaultAddress,
        uint256 indexed reserveId,
        uint256 credit
    );

    event SetInterestRateConfig(
        uint256 indexed reserveId,
        uint16 utilizationA,
        uint16 borrowingRateA,
        uint16 utilizationB,
        uint16 borrowingRateB,
        uint16 maxBorrowingRate
    );

    event SetReserveCapacity(uint256 indexed reserveId, uint256 cap);

    event SetReserveFeeRate(uint256 indexed reserveId, uint256 feeRate);

    event ReserveActivated(uint256 indexed reserveId);
    event ReserveDeActivated(uint256 indexed reserveId);
    event ReserveFrozen(uint256 indexed reserveId);
    event ReserveUnFreeze(uint256 indexed reserveId);
    event ReserveBorrowEnabled(uint256 indexed reserveId);
    event ReserveBorrowDisabled(uint256 indexed reserveId);

    struct ReserveStatus {
        uint256 reserveId;
        address underlyingTokenAddress;
        address eTokenAddress;
        address stakingAddress;
        uint256 totalLiquidity;
        uint256 totalBorrows;
        uint256 exchangeRate;
        uint256 borrowingRate;
    }

    struct PositionStatus {
        uint256 reserveId;
        address user;
        uint256 eTokenStaked;
        uint256 eTokenUnStaked;
        uint256 liquidity;
    }

    function getReserveStatus(
        uint256[] calldata reserveIdArr
    ) external view returns (ReserveStatus[] memory statusArr);

    function getPositionStatus(
        uint256[] calldata reserveIdArr,
        address user
    ) external view returns (PositionStatus[] memory statusArr);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying eTokens.
     * - E.g. User deposits 100 USDC and gets in return for specific amount of eUSDC
     * the eUSDC amount depends on the exchange rate between USDC and eUSDC
     * @param reserveId The ID of the reserve
     * @param amount The amount of reserve to be deposited
     * @param onBehalfOf The address that will receive the eTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of eTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external payable returns (uint256);

    /**
     * @dev User redeems eTokens in exchange for the underlying asset
     * E.g. User has 100 eUSDC, and the current exchange rate of eUSDC and USDC is 1:1.1
     * he will receive 110 USDC after redeem 100eUSDC
     * @param reserveId The id of the reserve
     * @param eTokenAmount The amount of eTokens to redeem
     *   - If the amount is type(uint256).max, all of user's eTokens will be redeemed
     * @param to Address that will receive the underlying tokens, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @param receiveNativeETH If receive native ETH, set this param to true
     * @return The underlying token amount user finally receive
     **/
    function redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) external returns (uint256);

    function newDebtPosition(uint256 reserveId) external returns (uint256);

    function getCurrentDebt(
        uint256 debtId
    ) external view returns (uint256 currentDebt, uint256 latestBorrowingIndex);

    /**
     * @dev Allows farming users to borrow a specific `amount` of the reserve underlying asset.
     * The user's borrowed tokens is transferred to the vault position contract and is recorded in the user's vault position(VaultPositionManageContract).
     * When debt ratio of user's vault position reach the liquidate limit,
     * the position will be liquidated and repay his debt(borrowed value + accrued interest)
     * @param onBehalfOf The beneficiary of the borrowing, receiving the tokens in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     */
    function borrow(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external;

    /**
     * @notice Repays borrowed underlying tokens to the reserve pool
     * The user's debt is recorded in the vault position(VaultPositionManageContract).
     * After this function successfully executed, user's debt should be reduced in VaultPositionManageContract.
     * @param onBehalfOf The user who repay debts in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     * @return The final amount repaid
     **/
    function repay(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external returns (uint256);

    function getUnderlyingTokenAddress(
        uint256 reserveId
    ) external view returns (address underlyingTokenAddress);

    function getETokenAddress(
        uint256 reserveId
    ) external view returns (address underlyingTokenAddress);

    function getStakingAddress(
        uint256 reserveId
    ) external view returns (address);

    function reserves(
        uint256
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address,
            address,
            uint256,
            DataTypes.InterestRateConfig memory,
            uint256,
            uint128,
            uint16,
            DataTypes.Flags memory
        );
}

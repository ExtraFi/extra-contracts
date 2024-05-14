// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - VT = Vault
 *  - LP = LendingPool
 *  - P = Pausable
 */
library Errors {
    //contract specific errors
    string internal constant VL_TRANSACTION_TOO_OLD = "0"; // 'Transaction too old'
    string internal constant VL_NO_ACTIVE_RESERVE = "1"; // 'Action requires an active reserve'
    string internal constant VL_RESERVE_FROZEN = "2"; // 'Action cannot be performed because the reserve is frozen'
    string internal constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "3"; // 'The current liquidity is not enough'
    string internal constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "4"; // 'User cannot withdraw more than the available balance'
    string internal constant VL_TRANSFER_NOT_ALLOWED = "5"; // 'Transfer cannot be allowed.'
    string internal constant VL_BORROWING_NOT_ENABLED = "6"; // 'Borrowing is not enabled'
    string internal constant VL_INVALID_DEBT_OWNER = "7"; // 'Invalid interest rate mode selected'
    string internal constant VL_BORROWING_CALLER_NOT_IN_WHITELIST = "8"; // 'The collateral balance is 0'
    string internal constant VL_DEPOSIT_TOO_MUCH = "9"; // 'Deposit too much'
    string internal constant VL_OUT_OF_CAPACITY = "10"; // 'There is not enough collateral to cover a new borrow'
    string internal constant VL_OUT_OF_CREDITS = "11"; // 'Out of credits, there is not enough credits to borrow'
    string internal constant VL_PERCENT_TOO_LARGE = "12"; // 'Percentage too large'
    string internal constant VL_ADDRESS_CANNOT_ZERO = "13"; // vault address cannot be zero
    string internal constant VL_VAULT_UN_ACTIVE = "14";
    string internal constant VL_VAULT_FROZEN = "15";
    string internal constant VL_VAULT_BORROWING_DISABLED = "16";
    string internal constant VL_NOT_WETH9 = "17";
    string internal constant VL_INSUFFICIENT_WETH9 = "18";
    string internal constant VL_INSUFFICIENT_TOKEN = "19";
    string internal constant VL_LIQUIDATOR_NOT_IN_WHITELIST = "20";
    string internal constant VL_COMPOUNDER_NOT_IN_WHITELIST = "21";
    string internal constant VL_VAULT_ALREADY_INITIALIZED = "22";
    string internal constant VL_TREASURY_ADDRESS_NOT_SET = "23";
    string internal constant VL_ETOKEN_AMOUNT_TOO_SMALL = "24";

    string internal constant VT_INVALID_RESERVE_ID = "40"; // invalid reserve id
    string internal constant VT_INVALID_POOL = "41"; // invalid AMM pool
    string internal constant VT_INVALID_VAULT_POSITION_MANAGER = "42"; // invalid vault position manager
    string internal constant VT_VAULT_POSITION_NOT_ACTIVE = "43"; // vault position is not active
    string internal constant VT_VAULT_POSITION_AUTO_COMPOUND_NOT_ENABLED = "44"; // 'auto compound not enabled'
    string internal constant VT_VAULT_POSITION_ID_INVALID = "45"; // 'VaultPositionId invalid'
    string internal constant VT_VAULT_PAUSED = "46"; // 'vault is paused'
    string internal constant VT_VAULT_FROZEN = "47"; // 'vault is frozen'
    string internal constant VT_VAULT_CALLBACK_INVALID_SENDER = "48"; // 'callback must be initiate by the vault self
    string internal constant VT_VAULT_DEBT_RATIO_TOO_LOW_TO_LIQUIDATE = "49"; // 'debt ratio haven't reach liquidate ratio'
    string internal constant VT_VAULT_POSITION_MANAGER_INVALID = "50"; // 'invalid vault manager'
    string internal constant VT_VAULT_POSITION_RANGE_STOP_DISABLED = "60"; // 'vault positions' range stop is disabled'
    string internal constant VT_VAULT_POSITION_RANGE_STOP_PRICE_INVALID = "61"; // 'invalid range stop price'
    string internal constant VT_VAULT_POSITION_OUT_OF_MAX_LEVERAGE = "62";
    string internal constant VT_VAULT_POSITION_SHARES_INVALID = "63";

    string internal constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "80"; // 'There is not enough liquidity available to borrow'
    string internal constant LP_CALLER_MUST_BE_LENDING_POOL = "81"; // 'Caller must be lending pool contract'
    string internal constant LP_BORROW_INDEX_OVERFLOW = "82"; // 'The borrow index overflow'
    string internal constant LP_IS_PAUSED = "83"; // lending pool is paused
}

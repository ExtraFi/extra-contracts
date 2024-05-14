// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ISwapExecutor {
    /// @notice doSwap, execute the swap in amm
    /// @param paramData The param passed in this function,
    /// the data is encoded in `SwapCallData`
    function doSwap(
        bytes calldata paramData
    ) external returns (uint256 srcAmountChange, uint256 dstAmountChange);
}

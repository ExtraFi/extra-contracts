// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ISwapExecutorManager {
    enum SwapType {
        swapWithExactInput,
        swapWithExactOutput
    }

    struct SwapCallData {
        uint256 swapExecutorId;
        SwapType swapType;
        address receiver;
        uint256 exactAmount;
        uint256 limitedAmount;
        uint256 deadline;
        bytes swapPath;
    }

    function validatePath(
        uint256 executorId,
        address srcToken,
        address dstToken,
        bytes calldata path
    ) external view;

    function getEnabledExecutor(
        uint256 id
    ) external view returns (address executorAddress);

    function generateDoSwapParam(
        SwapCallData memory param
    ) external view returns (bytes calldata data);
}

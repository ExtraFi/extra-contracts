// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IChainlinkOracle {
    function getPrice(
        address token0,
        address token1
    ) external view returns (bool, uint256);
}

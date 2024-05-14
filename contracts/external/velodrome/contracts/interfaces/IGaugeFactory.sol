// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGaugeFactory {
    function createGauge(
        address,
        address,
        address,
        address,
        bool,
        address[] memory
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IPair {
    function metadata()
        external
        view
        returns (
            uint dec0,
            uint dec1,
            uint r0,
            uint r1,
            bool st,
            address t0,
            address t1
        );

    function claimFees() external returns (uint, uint);

    function tokens() external view returns (address, address);

    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to) external returns (uint amount0, uint amount1);

    function mint(address to) external returns (uint liquidity);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);

    function getAmountOut(uint, address) external view returns (uint);

    function currentCumulativePrices()
        external
        view
        returns (
            uint reserve0Cumulative,
            uint reserve1Cumulative,
            uint blockTimestamp
        );

    function current(
        address tokenIn,
        uint amountIn
    ) external view returns (uint amountOut);

    function quote(
        address tokenIn,
        uint amountIn,
        uint granularity
    ) external view returns (uint amountOut);

    function prices(
        address tokenIn,
        uint amountIn,
        uint points
    ) external view returns (uint[] memory);
}

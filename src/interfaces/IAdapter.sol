pragma solidity 0.8.0;

interface IAdapter {
    function getPair(
        address tokenA,
        address tokenB,
        bytes memory additionalArgs
    ) external view virtual returns (address);

    function getAmountOut(
        address pair,
        uint amountIn,
        address tokenIn
    ) external view virtual returns (uint);
}

pragma solidity 0.8.0;
import "../interfaces/IAdapter.sol";
import "src/interfaces/IPairUniv2.sol";
import "lib/oz4.4.2/contracts/utils/math/SafeMath.sol";

contract Uniswapv2Adapter is IAdapter {
    using SafeMath for uint256;
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function getPair(
        address tokenA,
        address tokenB,
        bytes memory additionalArgs
    ) external view override returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        // this change of code allows swaps on a local network
        //pair = IUniswapV2Factory(factory).getPair(token0, token1);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            0x7419e6F310BB1Ce280b53e79B5CEb5bc920cFEA9, //TODO: @audit update
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"795e7cbc91a7a567bab085ffefe93c953d2a00456fa37497b81b2d66efc75528" // init code hash //TODO: @audit update
                        )
                    )
                )
            )
        );
    }

    function getAmountOut(
        address pair,
        uint amountIn,
        address tokenIn
    ) external view override returns (uint out) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        (uint reserve0, uint reserve1, ) = IPairUniv2(pair).getReserves();
        require(
            reserve0 > 0 && reserve1 > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        if (IPairUniv2(pair).token0() == tokenIn) {
            uint256 amountInWithFee = amountIn.mul(997);
            uint256 numerator = amountInWithFee.mul(reserve1);
            uint256 denominator = reserve0.mul(1000).add(amountInWithFee);
            out = numerator / denominator;
        } else {
            uint256 amountInWithFee = amountIn.mul(997);
            uint256 numerator = amountInWithFee.mul(reserve0);
            uint256 denominator = reserve1.mul(1000).add(amountInWithFee);
            out = numerator / denominator;
        }
    }
}

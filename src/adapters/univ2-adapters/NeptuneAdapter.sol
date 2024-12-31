pragma solidity 0.8.0;
import "src/interfaces/IAdapter.sol";
import "src/interfaces/IPairUniv2.sol";
import "lib/oz4.4.2/contracts/utils/math/SafeMath.sol";

contract NeptuneAdapter is IAdapter {
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
                            0x922FeCbE8dbFDfe85FfF4734046347B8E2ee7c82, //TODO: @audit update
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"75a006e6713aaf95877ce6f1df01031d9b533866995056f9664f1aa742ac42c4" // init code hash //TODO: @audit update
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

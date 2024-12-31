pragma solidity 0.8.0;
import "../interfaces/IAdapter.sol";
import "src/IPairFactory.sol";
import "src/interfaces/IPairSkydrome.sol";

contract SkyAdapterV2 is IAdapter {
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Router: ZERO_ADDRESS");
    }

    function getPair(
        address tokenA,
        address tokenB,
        bytes memory additionalArgs
    ) external view override returns (address) {
        bool is_stable = abi.decode(additionalArgs, (bool));
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                0x00A51d8b8d4580C9f4779deE09409d2D22704308,
                                keccak256(
                                    abi.encodePacked(token0, token1, is_stable)
                                ),
                                IPairFactory(
                                    0x00A51d8b8d4580C9f4779deE09409d2D22704308
                                ).pairCodeHash() // init code hash
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
        out = IPairSkydrome(pair).getAmountOut(amountIn, tokenIn);
    }
}

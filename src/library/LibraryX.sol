// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IAdapter} from "src/interfaces/IAdapter.sol";
import "lib/oz4.4.2/contracts/token/ERC20/ERC20.sol";

library LibraryX {
    struct Route {
        address from;
        address to;
        uint8 adapterId;
        bytes additionalArgs;
    }

    struct SwapDescription {
        IERC20 tokenIn;
        IERC20 tokenOut;
        address to;
        uint amountIn;
        uint amountOutMin;
        Route[] routes;
    }
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

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function getSortedPairAmounts(
        address _from,
        address _to,
        uint256 _latestAmountOut
    ) internal returns (uint, uint) {
        (address token0, address token1) = sortTokens(_from, _to);
        (uint amount0Out, uint amount1Out) = _from == token0
            ? (uint(0), _latestAmountOut)
            : (_latestAmountOut, uint(0));

        return (amount0Out, amount1Out);
    }

    function adapterCalls(
        uint _num,
        uint amountIn,
        Route[] memory _routes,
        IAdapter _adapter
    ) internal returns (IAdapter adapter_, address, uint) {
        address pair = _adapter.getPair(
            _routes[_num].from,
            _routes[_num].to,
            _routes[_num].additionalArgs
        ); //@audit current pair

        uint latestAmountOut = _adapter.getAmountOut(
            pair,
            amountIn,
            address(_routes[_num].from)
        ); // @audit should alwyays call current pair [i-1] [i]

        return (_adapter, pair, latestAmountOut);
    }
}

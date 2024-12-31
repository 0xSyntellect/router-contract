// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/IWETH.sol";
import "./interfaces/IAdapter.sol";


contract NeptuneXRouterV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Swapped(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event Fee(address _feeToken, uint _feeAmount);

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

    bool paused;

    modifier isPaused() {
        require(paused == false, "ADMIN_ERROR:Swaps Paused!");
        _;
    }

    IAdapter adapter;
    IERC20 tkn;

    address internal constant NATIVE =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IWETH public immutable weth;

    uint256 public feeRate = 0; // %1 = 1000
    uint256 internal constant MAX_FEE_RATE = 1000;
    uint256 internal constant PRECISION = 10000;
    address public feeAddress;

    mapping(uint8 => IAdapter) internal adapters; 

    constructor(address _feeAddress, address _weth) {
        feeAddress = _feeAddress;
        weth = IWETH(_weth);
    }

    function setAdapter(uint8 id, IAdapter _adapter) external onlyOwner {
        adapters[id] = _adapter;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        if (_feeRate <= MAX_FEE_RATE) {
            feeRate = _feeRate;
        }
    }

    function setPause() external onlyOwner {
        paused = !paused;
    }

    function rescueFunds(address token, uint256 amount) external onlyOwner {
        if (_isETH(IERC20(token))) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH_TRANSFER_FAILED");
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    function swapGeneral(
        SwapDescription calldata _swapDetails
    ) external payable isPaused nonReentrant {
        SwapDescription memory swapDetails = _swapDetails;

        require(
            address(swapDetails.tokenIn) != address(swapDetails.tokenOut) &&
                address(swapDetails.tokenIn) != address(0) &&
                address(swapDetails.tokenOut) != address(0),
            "INVALID_TOKENS"
        );

        require(swapDetails.amountIn > 0, "AmountIn cannot be zero");

        require(swapDetails.routes.length > 0, "Route cannot be empty");

        
        if (address(swapDetails.tokenIn) == NATIVE) {
            require(
                msg.value == swapDetails.amountIn,
                "NOT_ENOUGH_OR_TOO_MUCH_ETH"
            );
            require(
                swapDetails.routes[0].from == address(weth),
                "INVALID_TOKEN"
            );
            weth.deposit{value: swapDetails.amountIn}();
            swapDetails.tokenIn = IERC20(address(weth));
        } else {
            swapDetails.tokenIn.safeTransferFrom(
                msg.sender,
                address(this),
                swapDetails.amountIn
            );
        }

        

        if (feeRate != 0) {
            uint _fee = _takeFee(
                address(swapDetails.tokenIn),
                swapDetails.amountIn
            );

            swapDetails.amountIn = swapDetails.amountIn - _fee;

            emit Fee(address(swapDetails.tokenIn), _fee);
        }

        uint out = _swapTokenForTokenInput(swapDetails);

        require(swapDetails.amountOutMin <= out, "AMOUNTOUT_TOO_SMALL");

        if (address(swapDetails.tokenOut) == NATIVE) {
            require(
                swapDetails.routes[swapDetails.routes.length - 1].to ==
                    address(weth),
                "INVALID_TOKEN"
            );

            weth.withdraw(out);

            (bool success, ) = msg.sender.call{value: out}("");
            require(success, "ETH_TRANSFER_FAILED");
        } else {
            swapDetails.tokenOut.safeTransfer(msg.sender, out);
        }
        emit Swapped(
            address(swapDetails.tokenIn),
            address(swapDetails.tokenOut),
            swapDetails.amountIn,
            out
        );
    }

    function _swapTokenForTokenInput(
        SwapDescription memory _swapDetails
    ) internal returns (uint) {
        SwapDescription memory swapInfo = _swapDetails;

        uint length = swapInfo.routes.length;

        (address pair, uint256 latestAmountOut) = _pairCalls(
            0,
            swapInfo.amountIn,
            swapInfo.routes
        );

        swapInfo.tokenIn.safeTransfer(pair, swapInfo.amountIn);

        if (length == 1) {
            
            require(
                _executeSwap(
                    swapInfo.routes[0].from,
                    swapInfo.routes[0].to,
                    latestAmountOut,
                    pair,
                    address(this)
                ),
                "Swap Failed"
            );
            return latestAmountOut;
        } else {
            
            for (uint16 i = 0; i < length - 1; i++) {
                
                address nextPair = adapters[swapInfo.routes[i + 1].adapterId]
                    .getPair(
                        swapInfo.routes[i + 1].from,
                        swapInfo.routes[i + 1].to,
                        swapInfo.routes[i + 1].additionalArgs
                    ); 

                _executeSwap(
                    swapInfo.routes[i].from,
                    swapInfo.routes[i].to,
                    latestAmountOut,
                    pair,
                    nextPair
                );

                latestAmountOut = adapters[swapInfo.routes[i + 1].adapterId]
                    .getAmountOut(
                        nextPair,
                        latestAmountOut,
                        address(swapInfo.routes[i + 1].from)
                    ); 

                pair = nextPair;
            }

            bool success = _executeSwap(
                swapInfo.routes[length - 1].from,
                swapInfo.routes[length - 1].to,
                latestAmountOut,
                pair,
                address(this)
            );

            require(success, "Swap Failed");
        }

        return latestAmountOut;
    }

    function _pairCalls(
        uint _num,
        uint amountIn,
        Route[] memory _routes
    ) internal returns (address, uint) {
        IAdapter _adapter = adapters[_routes[_num].adapterId];

        address pair = _adapter.getPair(
            _routes[_num].from,
            _routes[_num].to,
            _routes[_num].additionalArgs
        ); 

        uint latestAmountOut = _adapter.getAmountOut(
            pair,
            amountIn,
            address(_routes[_num].from)
        ); 

        return (pair, latestAmountOut);
    }

    function _executeSwap(
        address _input,
        address _to,
        uint _latestAmountOut,
        address _pair,
        address callTarget
    ) internal returns (bool) {
        (address token0, address token1) = sortTokens(_input, _to);
        (uint amount0Out, uint amount1Out) = _input == token0
            ? (uint(0), _latestAmountOut)
            : (_latestAmountOut, uint(0));

        (bool success, ) = _pair.call(
            abi.encodeWithSignature(
                "swap(uint256,uint256,address,bytes)",
                amount0Out,
                amount1Out,
                callTarget,
                new bytes(0)
            )
        );

        return (success);
    }

    function _takeFee(
        address _inputToken,
        uint256 _amount
    ) internal returns (uint256 feeAmount) {
        feeAmount = (_amount * feeRate) / PRECISION;

        IERC20(_inputToken).safeTransfer(feeAddress, feeAmount);
    } 

    function _isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == NATIVE);
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

    receive() external payable {}
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import "src/NeptuneXRouterV1.sol";
import "src/adapters/SkyAdapterV1.sol";
import "src/adapters/SkyAdapterV2.sol";
import "src/adapters/Uniswapv2Adapter.sol";
import "src/interfaces/IPairSkydrome.sol";
import "src/IPairFactory.sol";

contract SwapScript is Script {
    NeptuneXRouterV1 swapRouter;

    address owner = 0x8f4a576a52382959FA384Bb5F7142387e5aA8f08;
    address weth = 0x4300000000000000000000000000000000000004;

    function setUp() public {
        swapRouter = NeptuneXRouterV1(
            payable(0x7CdAB4d1cb28e1d96CaeDf1E68bC1e0841BFdDbE)
        );
    }

    function run() public {
        IERC20 tokenIn = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); //native eth
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000003); //USDB

        uint amountIn = 0.001 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV1.Route[] memory routes = new NeptuneXRouterV1.Route[](
            1
        );

        routes[0].from = weth;
        routes[0].to = 0x4300000000000000000000000000000000000003; //USDB
        routes[0].adapterId = 0;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        NeptuneXRouterV1.SwapDescription memory swapDesc = NeptuneXRouterV1
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        vm.startBroadcast();

        //swapRouter.swapGeneral{value: amountIn}(swapDesc);
        vm.stopBroadcast();
    }
}

// forge script script/swapper.s.sol:SwapScript --rpc-url $BLAST_RPC2 --private-key $PRIVATE_KEY --gas-price 3000000000

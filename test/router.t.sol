// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "src/NeptuneXRouterV2.sol";
import "src/adapters/SkyAdapterV1.sol";
import "src/adapters/SkyAdapterV2.sol";
import "src/adapters/Uniswapv2Adapter.sol";
import "src/interfaces/IPairSkydrome.sol";
import "src/IPairFactory.sol";

contract RouterTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address deployer = makeAddr("deployer");
    address owner = 0x435D2a6b96d7A65EC2Ae430C0b1CBd71A6F09095;
    uint256 tknamt = 100 ether;
    address weth = 0x2fc1E147D6C10B6ACaE0AAC3EB0b528668045c84;
    NeptuneXRouterV2 swapRouter;
    SkyAdapterV1 skyv1;
    SkyAdapterV2 skyv2;
    Uniswapv2Adapter univ2Adapter;

    address internal constant NATIVE =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        vm.startPrank(owner);

        swapRouter = new NeptuneXRouterV2(owner, weth);
        skyv1 = new SkyAdapterV1();
        skyv2 = new SkyAdapterV2();
        univ2Adapter = new Uniswapv2Adapter();

        vm.stopPrank();

        vm.deal(alice, tknamt);
        vm.deal(bob, tknamt);
        vm.deal(deployer, tknamt);
        vm.deal(msg.sender, tknamt);

        vm.label(0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7, "mockSOL");
        vm.label(0x995f771753DD74827f93484400801683e9Ec5708, "mockBTC");
        vm.label(0xF7Ed87404C0997f008F538563Ac5a3C7878141bE, "mockUSDC");
        vm.label(0x2fc1E147D6C10B6ACaE0AAC3EB0b528668045c84, "mockWETH");
        vm.label(0x29D041C4cf8DEbF48aEB4265C99CCd889960eBA5, "mockDOGE");

        vm.label(
            0xB2210cEf4aCA72679a165d9CCea782D1e53d5448,
            "WETHUSDC-SKYV1LP"
        );

        vm.label(0x485b8265b47b9cd9F853FAC1e18f943F4a40003a, "USDCSOL-SKYV1LP");

        vm.label(0x2DB2965Ec9Ac65dcEabf4879519D601a1868A0eb, "SOLDOGE-SKYV1LP");
        vm.label(0x624FFD8f1EdDe5626F59286ADe337189ccEBD833, "SOLDOGE-SKYV2LP");
    }

    function test_swapGeneral_singlehop() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7); //mockSOL
        IERC20 tokenOut = IERC20(0x995f771753DD74827f93484400801683e9Ec5708); //mockBTC

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = 1 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        routes[0].from = 0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7; //mockSOL
        routes[0].to = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[1].to = 0x995f771753DD74827f93484400801683e9Ec5708; //mockBTC
        routes[1].adapterId = 1;
        routes[1].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        swapRouter.setAdapter(1, skyv1);
        swapRouter.setAdapter(2, skyv2);
        swapRouter.setAdapter(3, univ2Adapter);

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_swapGeneral_mulithop() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7); //mockSOL
        IERC20 tokenOut = IERC20(0x995f771753DD74827f93484400801683e9Ec5708); //mockBTC

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = 1 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        routes[0].from = 0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7; //mockSOL
        routes[0].to = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[1].to = 0x995f771753DD74827f93484400801683e9Ec5708; //mockBTC
        routes[1].adapterId = 1;
        routes[1].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        swapRouter.setAdapter(1, skyv1);
        swapRouter.setAdapter(2, skyv2);
        swapRouter.setAdapter(3, univ2Adapter);

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_swapGeneral_mulithop_eth() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // weth
        IERC20 tokenOut = IERC20(0x995f771753DD74827f93484400801683e9Ec5708); //mockBTC

        uint initBalance0 = owner.balance;
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = 0.01 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        routes[0].from = weth;
        routes[0].to = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[1].to = 0x995f771753DD74827f93484400801683e9Ec5708; //mockBTC
        routes[1].adapterId = 1;
        routes[1].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        swapRouter.setAdapter(1, skyv1);
        swapRouter.setAdapter(2, skyv2);
        swapRouter.setAdapter(3, univ2Adapter);

        swapRouter.swapGeneral{value: amountIn}(swapDesc);

        assertEq(initBalance0 > owner.balance, true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_swapGeneral_mulithop_eth2() public {
        
        
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // weth
        IERC20 tokenOut = IERC20(0x29D041C4cf8DEbF48aEB4265C99CCd889960eBA5); //mockDoge

        uint initBalance0 = owner.balance;
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = 0.001 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            3
        );

        routes[0].from = weth;
        routes[0].to = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[1].to = 0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7; //mockSOL
        routes[1].adapterId = 1;
        routes[1].additionalArgs = abi.encode(stable);

        routes[2].from = 0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7; //mockSOL
        routes[2].to = 0x29D041C4cf8DEbF48aEB4265C99CCd889960eBA5; //mockDoge
        routes[2].adapterId = 2;
        routes[2].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        swapRouter.setAdapter(1, skyv1);
        swapRouter.setAdapter(2, skyv2);
        swapRouter.setAdapter(3, univ2Adapter);

        swapRouter.swapGeneral{value: amountIn}(swapDesc);

        assertEq(initBalance0 > owner.balance, true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_swapGeneral_mulithop_eth_output() public {
        
        
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x29D041C4cf8DEbF48aEB4265C99CCd889960eBA5); //mockDoge
        IERC20 tokenOut = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // native eth

        uint initBalanceTokenIn = tokenIn.balanceOf(owner);
        uint initBalanceTokenOut = owner.balance;

        uint amountIn = 0.1 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            3
        );

        bool stable = false;

        routes[0].from = 0x29D041C4cf8DEbF48aEB4265C99CCd889960eBA5; //mockDoge
        routes[0].to = 0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7; //mockSOL
        routes[0].adapterId = 2;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0xB2eb65Bbc78Cb8FbB3c31BEC4E50B406AcCC91b7; //mockSOL
        routes[1].to = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[1].adapterId = 1;
        routes[1].additionalArgs = abi.encode(stable);

        routes[2].from = 0xF7Ed87404C0997f008F538563Ac5a3C7878141bE; //mockUSDC
        routes[2].to = weth;
        routes[2].adapterId = 1;
        routes[2].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        swapRouter.setAdapter(1, skyv1);
        swapRouter.setAdapter(2, skyv2);
        swapRouter.setAdapter(3, univ2Adapter);

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral{value: amountIn}(swapDesc);

        assertEq(initBalanceTokenIn > tokenIn.balanceOf(owner), true);

        // assertEq(initBalanceTokenOut < owner.balance, true); // @audit issue with eth balance increase because of gas spent, need to add usedGas snapshot

        vm.stopPrank();
    }
}

// forge test --fork-url $SCROLL_SEPOLIA_RPC

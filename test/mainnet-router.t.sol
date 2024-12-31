// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

//import "src/NeptuneXRouterV2.sol";
import "src/NeptuneXRouterV2.sol";
import "src/adapters/Uniswapv2Adapter.sol";
import "src/interfaces/IPairSkydrome.sol";
import "src/IPairFactory.sol";
import "src/interfaces/IWETH.sol";

import "src/adapters/univ2-adapters/Blasterv2Adapter.sol";
import "src/adapters/univ2-adapters/Dyorswapv2Adapter.sol";
import "src/adapters/univ2-adapters/Monoswapv2Adapter.sol";
import "src/adapters/univ2-adapters/Ringv2Adapter.sol";
import "src/adapters/univ2-adapters/Thrusterv2Adapter.sol";
import "src/adapters/univ2-adapters/Thrusterv2Adapter03.sol";



contract MainnetRouterTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address deployer = makeAddr("deployer");
    address owner = 0x8f4a576a52382959FA384Bb5F7142387e5aA8f08;
    uint256 tknamt = 100 ether;
    address weth = 0x4300000000000000000000000000000000000004;
    //NeptuneXRouterV2 swapRouter;
    NeptuneXRouterV2 swapRouter;
    Blasterv2Adapter blasterAdapter;
    Dyorswapv2Adapter dyorAdapter;
    Monoswapv2Adapter monoAdapter;
    Ringv2Adapter ringAdapter;
    Thrusterv2Adapter thrustAdatper;
    Thrusterv2Adapter03 thrust03Adapter;

    address internal constant NATIVE =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        vm.startPrank(owner);

        // NeptuneXRouterV2 router = NeptuneXRouterV2(
        //     payable(0x7CdAB4d1cb28e1d96CaeDf1E68bC1e0841BFdDbE)
        // );

        swapRouter = new NeptuneXRouterV2(owner, weth);

        thrustAdatper = new Thrusterv2Adapter();
        blasterAdapter = new Blasterv2Adapter();
        monoAdapter = new Monoswapv2Adapter();
        dyorAdapter = new Dyorswapv2Adapter();
        ringAdapter = new Ringv2Adapter();
        thrust03Adapter = new Thrusterv2Adapter03();

        swapRouter.setAdapter(0, thrustAdatper);
        swapRouter.setAdapter(1, blasterAdapter);
        swapRouter.setAdapter(2, monoAdapter);
        swapRouter.setAdapter(3, dyorAdapter);
        swapRouter.setAdapter(4, ringAdapter);
        swapRouter.setAdapter(5, thrust03Adapter);

        vm.stopPrank();

        vm.deal(alice, tknamt);
        vm.deal(bob, tknamt);
        vm.deal(deployer, tknamt);
        vm.deal(owner, tknamt);
        vm.deal(msg.sender, tknamt);

        address wethWhale = 0x50664edE715e131F584D3E7EaAbd7818Bb20A068;
        address usdbWhale = 0x020cA66C30beC2c4Fe3861a94E4DB4A498A35872;
        address pacWhale = 0xebb74B95F8598e56Db85c8e0Ac1160b62D012776;

        vm.label(wethWhale, "wethWhale");
        vm.label(usdbWhale, "usdbWhale");
        vm.label(pacWhale, "packWhale");

        vm.label(0x4300000000000000000000000000000000000004, "WETH");
        vm.label(0x4300000000000000000000000000000000000003, "USDB");
        vm.label(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06, "PAC");

        vm.startPrank(wethWhale);
        IERC20 _weth = IERC20(0x4300000000000000000000000000000000000003);
        uint wethBalance = _weth.balanceOf(wethWhale);
        _weth.transfer(owner, wethBalance / 5);
        _weth.transfer(alice, wethBalance / 5);
        _weth.transfer(bob, wethBalance / 5);
        _weth.transfer(deployer, wethBalance / 5);
        _weth.transfer(msg.sender, wethBalance / 5);
        vm.stopPrank();

        vm.startPrank(usdbWhale);

        IERC20 _usdb = IERC20(0x4300000000000000000000000000000000000004);
        uint usdbBalance = _usdb.balanceOf(usdbWhale);

        _usdb.transfer(owner, usdbBalance / 5);
        _usdb.transfer(alice, usdbBalance / 5);
        _usdb.transfer(bob, usdbBalance / 5);
        _usdb.transfer(deployer, usdbBalance / 5);
        _usdb.transfer(msg.sender, usdbBalance / 5);
        vm.stopPrank();

        vm.startPrank(pacWhale);
        IERC20 _pac = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06);
        uint pacBalance = _usdb.balanceOf(pacWhale);

        _pac.transfer(owner, pacBalance / 5);
        _pac.transfer(alice, pacBalance / 5);
        _pac.transfer(bob, pacBalance / 5);
        _pac.transfer(deployer, pacBalance / 5);
        _pac.transfer(msg.sender, pacBalance / 5);
        vm.stopPrank();
    }

    function test_swapGeneral_singlehop() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06);
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000004);

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            1
        );

        routes[0].from = address(tokenIn);
        routes[0].to = address(tokenOut);
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_swapGeneral_mulithop() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06); //PAC
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000003); //USDB

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;

        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        routes[0].from = 0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06; //PAC
        routes[0].to = 0x4300000000000000000000000000000000000004; //WETH
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0x4300000000000000000000000000000000000004; //WETH
        routes[1].to = 0x4300000000000000000000000000000000000003; //USDB
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

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_ethinput_swapGeneral_mulithop() public {
        vm.label(
            0x3b5d3f610Cc3505f4701E9FB7D0F0C93b7713adD,
            "WETHUSDBLP-BLASTER"
        );
        vm.label(
            0xf8b1EE004C9b133064011BC6cc50fc6648FDa05D,
            "USDBPACTHLP-BLASTER"
        );
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // native eth
        IERC20 tokenOut = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06); //PAC

        uint initBalance0 = owner.balance;
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = 0.0000001 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        routes[0].from = weth;
        routes[0].to = 0x4300000000000000000000000000000000000003; //USDB
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0x4300000000000000000000000000000000000003; //USDB
        routes[1].to = 0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06; //PAC
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

        swapRouter.swapGeneral{value: amountIn}(swapDesc);

        assertEq(initBalance0 > owner.balance, true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_ethinput2_swapGeneral_mulithop() public {
        vm.label(
            0x3b5d3f610Cc3505f4701E9FB7D0F0C93b7713adD,
            "WETHUSDBLP-BLASTER"
        );
        vm.label(
            0xf8b1EE004C9b133064011BC6cc50fc6648FDa05D,
            "USDBPACTHLP-BLASTER"
        );

        vm.label(
            0x86437A9464513F7A9295eB6428662Ee9C8D657bC,
            "USDBezETHLP-BLASTER"
        );
        vm.label(0x2416092f143378750bb29b79eD961ab195CcEea5, "ezETH");

        //vm.label(0x74e65E4673Ac2AA4D47b0c6A822B6D9dC7297032,"exETH-)

        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // native eth
        IERC20 tokenOut = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06); //PAC

        uint initBalance0 = owner.balance;
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = 0.0000001 ether;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            3
        );

        routes[0].from = weth;
        routes[0].to = 0x4300000000000000000000000000000000000003; //USDB
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0x4300000000000000000000000000000000000003; //USDB
        routes[1].to = 0x2416092f143378750bb29b79eD961ab195CcEea5; //ezETH
        routes[1].adapterId = 1;
        routes[1].additionalArgs = abi.encode(stable);

        routes[2].from = 0x2416092f143378750bb29b79eD961ab195CcEea5; //ezETH
        routes[2].to = 0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06; //PAC
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

        swapRouter.swapGeneral{value: amountIn}(swapDesc);

        assertEq(initBalance0 > owner.balance, true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }

    function test_ethoutput_swapGeneral_mulithop() public {
        vm.label(
            0xf8b1EE004C9b133064011BC6cc50fc6648FDa05D,
            "PACUSDBLP-BLASTER"
        );
        vm.label(
            0x3b5d3f610Cc3505f4701E9FB7D0F0C93b7713adD,
            "USDbWETHLP-BLASTER"
        );
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06); //PAC
        IERC20 tokenOut = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // native eth

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = owner.balance;

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        bool stable = false;

        routes[0].from = 0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06; //PAC
        routes[0].to = 0x4300000000000000000000000000000000000003; //USDB
        routes[0].adapterId = 1;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0x4300000000000000000000000000000000000003; //USDB
        routes[1].to = 0x4300000000000000000000000000000000000004; //WETH
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

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral{value: amountIn}(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);

        //assertEq(initBalance1 < owner.balance, true); // @audit issue with eth balance increase because of gas spent, need to add usedGas snapshot

        vm.stopPrank();
    }

    function test_approval_exploit() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06); //PAC
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000003); //USDB

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;

        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            2
        );

        routes[0].from = 0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06; //PAC
        routes[0].to = 0x4300000000000000000000000000000000000004; //WETH
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        routes[1].from = 0x4300000000000000000000000000000000000004; //WETH
        routes[1].to = 0x4300000000000000000000000000000000000003; //USDB
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

        tokenIn.approve(address(swapRouter), type(uint256).max);

        swapRouter.swapGeneral(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }
    function test_pause() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06);
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000004);

        uint initBalance0 = tokenIn.balanceOf(owner);
        uint initBalance1 = tokenOut.balanceOf(owner);

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;
        address to = owner;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            1
        );

        routes[0].from = address(tokenIn);
        routes[0].to = address(tokenOut);
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        tokenIn.approve(address(swapRouter), type(uint256).max);

        //swapRouter.setPause();

        vm.expectRevert();
        swapRouter.swapGeneral(swapDesc);

        //swapRouter.setPause();
        swapRouter.swapGeneral(swapDesc);

        assertEq(initBalance0 > tokenIn.balanceOf(owner), true);
        assertEq(initBalance1 < tokenOut.balanceOf(owner), true);

        vm.stopPrank();
    }
    function test_fees_token() public {
        vm.startPrank(owner);

        swapRouter.setFeeAddress(alice);
        swapRouter.setFeeRate(1000);
        vm.stopPrank();

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06);
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000003);

        uint initBalance0 = tokenIn.balanceOf(bob);
        uint initBalance1 = tokenOut.balanceOf(bob);

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;
        address to = bob;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            1
        );

        routes[0].from = address(tokenIn);
        routes[0].to = address(tokenOut);
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        uint feeBalance = tokenIn.balanceOf(alice);

        vm.startPrank(bob);
        tokenIn.approve(address(swapRouter), type(uint256).max);
        swapRouter.swapGeneral(swapDesc);
        vm.stopPrank();

        assertEq(feeBalance < tokenIn.balanceOf(alice), true);
    }

    function test_fees_eth() public {
        vm.startPrank(owner);
        swapRouter.setFeeAddress(alice);
        swapRouter.setFeeRate(1000);
        vm.stopPrank();

        IERC20 tokenIn = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000003);

        uint initBalance0 = bob.balance;
        uint initBalance1 = tokenOut.balanceOf(bob);

        uint amountIn = initBalance0 / 2;
        uint amountOutMin = 0;
        address to = bob;

        NeptuneXRouterV2.Route[] memory routes = new NeptuneXRouterV2.Route[](
            1
        );

        routes[0].from = weth;
        routes[0].to = address(tokenOut);
        routes[0].adapterId = 1;
        bool stable = false;
        routes[0].additionalArgs = abi.encode(stable);

        NeptuneXRouterV2.SwapDescription memory swapDesc = NeptuneXRouterV2
            .SwapDescription(
                tokenIn,
                tokenOut,
                to,
                amountIn,
                amountOutMin,
                routes
            );

        uint feeBalance = IERC20(0x4300000000000000000000000000000000000004)
            .balanceOf(alice);

        vm.startPrank(bob);

        swapRouter.swapGeneral{value: amountIn}(swapDesc);
        vm.stopPrank();

        assertEq(
            feeBalance <
                IERC20(0x4300000000000000000000000000000000000004).balanceOf(
                    alice
                ),
            true
        );
    }

    function test_rescue_funds() public {
        vm.startPrank(owner);

        IERC20 tokenIn = IERC20(0x5ffd9EbD27f2fcAB044c0f0a26A45Cb62fa29c06);
        IERC20 tokenOut = IERC20(0x4300000000000000000000000000000000000004);
        uint initBalance = tokenIn.balanceOf(owner);
        tokenIn.transfer(address(swapRouter), 100);
        swapRouter.rescueFunds(
            address(tokenIn),
            tokenIn.balanceOf(address(swapRouter))
        );
        assertEq(initBalance == tokenIn.balanceOf(owner), true);
        vm.stopPrank();
    }
}

// forge test --fork-url $BLAST_RPC2

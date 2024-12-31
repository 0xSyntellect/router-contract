// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import "src/NeptuneXRouterV1.sol";

import "src/adapters/univ2-adapters/Thrusterv2Adapter.sol";
import "src/adapters/univ2-adapters/Blasterv2Adapter.sol";
import "src/adapters/univ2-adapters/Monoswapv2Adapter.sol";
import "src/adapters/univ2-adapters/Dyorswapv2Adapter.sol";
import "src/adapters/univ2-adapters/Ringv2Adapter.sol";
import "src/adapters/univ2-adapters/NeptuneAdapter.sol";
import "src/adapters/univ2-adapters/Thrusterv2Adapter03.sol";

contract MainnetDeployerScript2 is Script {
    function setUp() public {}

    function run() public {
        //address owner = 0x8f4a576a52382959FA384Bb5F7142387e5aA8f08;
        //address weth = 0x4300000000000000000000000000000000000004; // @audit eth address check for mainnet and testnet

        vm.startBroadcast();

        //NeptuneAdapter neptuneAdapter = new NeptuneAdapter();
        //Thrusterv2Adapter thrusterAdapter = new Thrusterv2Adapter();
        //Blasterv2Adapter blasterAdapter = new Blasterv2Adapter();
        //Monoswapv2Adapter monoAdapter = new Monoswapv2Adapter();
        //Dyorswapv2Adapter dyorAdapter = new Dyorswapv2Adapter();
        //Ringv2Adapter ringAdapter = new Ringv2Adapter();
        Thrusterv2Adapter03 thruster03Adapter = new Thrusterv2Adapter03();

        NeptuneXRouterV1 router = NeptuneXRouterV1(
            payable(0x7CdAB4d1cb28e1d96CaeDf1E68bC1e0841BFdDbE)
        );

        // router.setAdapter(1, blasterAdapter);
        // router.setAdapter(2, monoAdapter);
        // router.setAdapter(3, dyorAdapter);
        // router.setAdapter(4, ringAdapter);
        //router.setAdapter(5, neptuneAdapter);
        router.setAdapter(6, thruster03Adapter);

        vm.stopBroadcast();
    }
}

// forge script script/mainnet-deployer2.s.sol:MainnetDeployerScript2 --rpc-url $BLAST_RPC2 --private-key $PRIVATE_KEY --broadcast --gas-price 11000000

// 0xf41766d8

// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setRouterSelector(bytes4,address)()"  0xf41766d8 0x79c72e3fFb2aE167cD90e3947CcEaefb8B826950 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000
// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setRouterSelector(bytes4,address)()"  0xf41766d8 0x969D5D9d7F968ECF4D8DF4EfEbFB2852fE471614 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000

// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setAvailableRouter(bool,address)()"  true 0x79c72e3fFb2aE167cD90e3947CcEaefb8B826950 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000
// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setAvailableRouter(bool,address)()"  true 0x969D5D9d7F968ECF4D8DF4EfEbFB2852fE471614 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000

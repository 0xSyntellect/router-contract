// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import "src/NeptuneXRouterV1.sol";
import "src/adapters/SkyAdapterV1.sol";
import "src/adapters/SkyAdapterV2.sol";
import "src/adapters/Uniswapv2Adapter.sol";

contract DeployerScript is Script {
    function setUp() public {}

    function run() public {
        address owner = 0x435D2a6b96d7A65EC2Ae430C0b1CBd71A6F09095;
        address weth = 0x2fc1E147D6C10B6ACaE0AAC3EB0b528668045c84;

        vm.startBroadcast();

        SkyAdapterV1 adapter1 = new SkyAdapterV1();
        SkyAdapterV2 adapter2 = new SkyAdapterV2();
        Uniswapv2Adapter uniAdapter = new Uniswapv2Adapter();

        NeptuneXRouterV1 router = new NeptuneXRouterV1(owner, weth);
        router.setAdapter(1, adapter1);
        router.setAdapter(2, adapter2);
        router.setAdapter(3, uniAdapter);

        vm.stopBroadcast();
    }
}

// forge script script/deployer.s.sol:DeployerScript --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --broadcast --gas-price 3000000000

// 0xf41766d8

// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setRouterSelector(bytes4,address)()"  0xf41766d8 0x79c72e3fFb2aE167cD90e3947CcEaefb8B826950 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000
// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setRouterSelector(bytes4,address)()"  0xf41766d8 0x969D5D9d7F968ECF4D8DF4EfEbFB2852fE471614 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000

// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setAvailableRouter(bool,address)()"  true 0x79c72e3fFb2aE167cD90e3947CcEaefb8B826950 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000
// cast send 0xA39Ef5b5ae7706639816E019671Db5aa00229EF1 "setAvailableRouter(bool,address)()"  true 0x969D5D9d7F968ECF4D8DF4EfEbFB2852fE471614 --rpc-url $SCROLL_SEPOLIA_RPC --private-key $PRIVATE_KEY --gas-price 3000000000

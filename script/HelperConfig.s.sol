// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public configNet;

    uint8 private constant DECIAML = 8;
    int256 private constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address pricefeed;
    }

    constructor() {
        //sepolia test chain id
        if (block.chainid == 11155111) {
            configNet = getSepoliaEthConfig();
        } else {
            configNet = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetwork)
    {
        sepoliaNetwork = NetworkConfig({
            pricefeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    function getAnvilEthConfig()
        public
        returns (NetworkConfig memory anvilNetwork)
    {
        if (configNet.pricefeed != address(0)) {
            return configNet; // 已经运行过一遍了，就不再重复运行下面的vm代码，是防止重复调用吗？
        } else {
            vm.startBroadcast();
            MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
                DECIAML,
                INITIAL_PRICE
            );
            vm.stopBroadcast();

            anvilNetwork = NetworkConfig({
                pricefeed: address(mockV3Aggregator)
            });
        }
    }
}

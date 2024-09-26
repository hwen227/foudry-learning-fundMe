// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function fundFundme(address mostRecentlyDeployed) public payable {
        FundMe(payable(mostRecentlyDeployed)).fund{value: msg.value}();
        console.log("Funded FundMe with %s", msg.value);

        // vm.startBroadcast();
        // FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        // vm.stopBroadcast();
        // console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address recent_contract = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        fundFundme(recent_contract);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}

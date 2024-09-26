// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DeployFundMe, FundMe} from "../../script/FundMeDeploy.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Integration.s.sol";

contract FundMeInteractionTest is Test {
    DeployFundMe deployFundMe;
    FundMe fundMe;
    address alice;

    uint256 public constant SEND_VALUE = 0.1 ether;

    function setUp() external {
        alice = makeAddr("alice");
        vm.deal(alice, 10 ether);

        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testUserCanFundAndOwnerWithdraw() public {
        uint256 preUserBalance = address(alice).balance;
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance;

        console.log(
            "Alice balance before transaction: %s",
            address(alice).balance
        );

        // vm.prank(alice);
        // fundMe.fund{value: SEND_VALUE}();

        vm.startPrank(alice);
        FundFundMe ffd = new FundFundMe();
        ffd.fundFundme{value: SEND_VALUE}(address(fundMe));
        vm.stopPrank();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterUserBalance = address(alice).balance;
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;

        assert(address(fundMe).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
}

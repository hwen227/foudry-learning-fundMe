// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {DeployFundMe, FundMe} from "../../script/FundMeDeploy.s.sol";
import "../../src/FundMe.sol";

contract FundMeTest is Test {
    DeployFundMe deployFundMe;
    FundMe fundMe;
    address alice;

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: 1 ether}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function setUp() external {
        alice = makeAddr("alice");
        vm.deal(alice, 10 ether);

        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIsOwnerMe() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    //  =================fund() TEST=================

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStructure() public {
        vm.startPrank(alice);

        fundMe.fund{value: 1 ether}();
        uint256 amount = fundMe.getAddressToAmountFunded(alice);
        assertEq(amount, 1 ether);
        fundMe.fund{value: 2 ether}();

        vm.stopPrank();

        amount = fundMe.getAddressToAmountFunded(alice);
        assertEq(amount, 3 ether);
    }

    function testFunderArrayUpdate() public {
        fundMe.fund{value: 1 ether}();
        fundMe.fund{value: 2 ether}();

        vm.prank(alice);
        fundMe.fund{value: 1 ether}();

        uint256 amount = fundMe.getAddressToAmountFunded(fundMe.getFunder(0));
        assertEq(amount, 3e18);

        uint256 amount2 = fundMe.getAddressToAmountFunded(fundMe.getFunder(1));
        assertEq(amount2, 1e18);
    }

    //=====================================================

    //==============withdraw() TEST========================

    function testWithdrawNotOwner() public funded {
        vm.prank(alice);
        vm.expectRevert(FundMe__NotOwner.selector);
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunderV1() public funded {
        uint256 startFundBalance = address(fundMe).balance;

        uint256 startOwnerBalance = fundMe.getOwner().balance;
        console.log(startFundBalance);

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endFundBalance = address(fundMe).balance;
        uint256 endOwnerBalance = fundMe.getOwner().balance;

        assertEq(endFundBalance, 0);
        assertEq(endOwnerBalance, startFundBalance + startOwnerBalance);
    }

    function testWithdrawFromMultipleFunder() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (
            uint160 index = startingFunderIndex;
            index < numberOfFunders + startingFunderIndex;
            index++
        ) {
            hoax(address(index), 2 ether);
            fundMe.fund{value: 1 ether}();
        }

        uint256 startFundBalance = address(fundMe).balance;
        uint256 startOwnerBalance = fundMe.getOwner().balance;

        console.log(startFundBalance);

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endFundBalance = address(fundMe).balance;
        uint256 endOwnerBalance = fundMe.getOwner().balance;

        assertEq(endFundBalance, 0);
        assertEq(endOwnerBalance, startFundBalance + startOwnerBalance);
    }

    function testWithdrawFromASingleFunderV2() public funded {
        vm.txGasPrice(1);
        uint256 gasStart = gasleft();

        uint256 startFundBalance = address(fundMe).balance;
        uint256 startOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();

        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        console.log("Withdraw consummed: %d gas", gasUsed);

        uint256 endFundBalance = address(fundMe).balance;
        uint256 endOwnerBalance = fundMe.getOwner().balance;

        assertEq(endFundBalance, 0);
        assertEq(endOwnerBalance, startFundBalance + startOwnerBalance);
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Vaule at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), 1 ether);
            fundMe.fund{value: 1 ether}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * 1 ether ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }
}

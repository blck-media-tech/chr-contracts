// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";

contract CHRPresaleTest_BeforePresale is Test, CHRPresaleHelper, IPresale {
    uint256 timeDelay = 1 days;

    function setUp() public {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        presaleContract = new CHRPresaleHarness(
            address(tokenContract),
            address(mockAggregator),
            address(mockUSDT),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );
    }

    function test_SetUpState() public {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp + timeDelay);
        assertEq(presaleContract.saleEndTime(), block.timestamp + timeDelay * 2);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), 0);
    }

    function testFuzz_BuyWithEth_RevertWhen_PresaleNotStarted(uint256 _amount, address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithEth(_amount);
    }

    function testFuzz_BuyWithUSDT_RevertWhen_PresaleNotStarted(uint256 _amount, address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount);
    }

    function testFuzz_Claim_RevertWhen_PresaleNotStarted(address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.claim();
    }
}

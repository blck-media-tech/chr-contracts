// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";
import "./CHRPresale.timeIndependent.t.sol";

/// @title Test for Chancer presale in case current timestamp is before presale start
contract CHRPresaleTest_BeforePresale is CHRPresaleTest_TimeIndependent {
    /// @notice Expected state - contract deployed, preasle not started, claim not started
    function setUp() public virtual override {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        presaleContract = new CHRPresaleHarness(
            address(tokenContract),
            address(mockAggregator),
            address(mockBUSD),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );
    }

    /// @notice Ensure that test initial state was set up correctly
    function test_SetUpState() public override {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.busdToken()), address(mockBUSD));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp + timeDelay);
        assertEq(presaleContract.saleEndTime(), block.timestamp + timeDelay * 2);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), 0);
    }

    /// @custom:function buyWithBNB
    /// @notice User shouldn't be able to buy with BNB before presale started
    function testFuzz_BuyWithBnb_RevertWhen_PresaleNotStarted(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithBnb(_amount, _referrerId);
    }

    /// @custom:function buyWithBUSD
    /// @notice User shouldn't be able to buy with BUSD before presale started
    function testFuzz_BuyWithBUSD_RevertWhen_PresaleNotStarted(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithBUSD(_amount, _referrerId);
    }

    /// @custom:function claim
    /// @notice User shouldn't be able to claim tokens before presale started
    function testFuzz_Claim_RevertWhen_PresaleNotStarted(address _user) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.claim();
    }
}

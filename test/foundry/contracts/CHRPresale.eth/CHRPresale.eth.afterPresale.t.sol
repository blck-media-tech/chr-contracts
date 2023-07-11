// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.eth.helper.t.sol";
import "./CHRPresale.eth.timeIndependent.t.sol";

/// @title Test for Chancer presale in case current timestamp is after presale end and claim is not yet started
contract CHRPresaleETHTest_AfterPresale is CHRPresaleETHTest_TimeIndependent {
    /// @notice Expected state - contract deployed, preasle ended, claim not started
    function setUp() public virtual override {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        presaleContract = new CHRPresaleETHHarness(
            address(tokenContract),
            address(mockAggregator),
            address(mockUSDT),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        vm.warp(saleEndTime);
    }

    /// @notice Ensure that test initial state was set up correctly
    function test_SetUpState() public override {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp - timeDelay);
        assertEq(presaleContract.saleEndTime(), block.timestamp);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), 0);
    }

    /// @custom:function buyWithETH
    /// @notice User shouldn't be able to buy with ETH after presale ended
    function testFuzz_BuyWithEth_RevertWhen_PresaleEnded(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithNativeCoin(_amount, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice User shouldn't be able to buy with USDT after presale ended
    function testFuzz_BuyWithUSDT_RevertWhen_PresaleEnded(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithUSD(_amount, _referrerId);
    }

    /// @custom:function configureClaim
    /// @notice Expected result:
    ///         - claimStartTime
    function testFuzz_ConfigureClaim(uint256 _totalTokensSold, uint256 _claimStartTime) public {
        vm.assume(type(uint256).max / 1e18 > _totalTokensSold);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        deal(address(tokenContract), address(presaleContract), _totalTokensSold * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), _totalTokensSold * 1e18);

        vm.expectEmit(true, true, true, true);
        emit ClaimTimeUpdated(_claimStartTime, block.timestamp);

        presaleContract.configureClaim(_claimStartTime);
        assertEq(presaleContract.claimStartTime(), _claimStartTime);
    }

    /// @custom:function claim
    /// @notice User shouldn't be able to claim tokens before claim started
    function testFuzz_Claim_RevertWhen_PresaleEnded(address _user) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.claim();
    }
}

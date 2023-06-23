// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.v2.helper.t.sol";
import "./CHRPresale.v2.timeIndependent.t.sol";

/// @title Test for Chancer presale in case current timestamp is before presale start
contract CHRPresaleV2Test_BeforePresale is CHRPresaleV2Test_TimeIndependent {
    /// @notice Expected state - contract deployed, preasle not started, claim not started
    function setUp() public virtual override {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        presaleContract = new CHRPresaleV2Harness(
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

    /// @custom:function configureClaim
    /// @notice Execution should be reverted if presale is not ended
    function testFuzz_ConfigureClaim(uint256 _totalTokensSold, uint256 _claimStartTime) public {
        vm.assume(type(uint256).max / 1e18 > _totalTokensSold);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        deal(address(tokenContract), address(presaleContract), _totalTokensSold * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), _totalTokensSold * 1e18);

        vm.expectRevert(abi.encodeWithSelector(PresaleNotEnded.selector));

        presaleContract.configureClaim(_claimStartTime);
    }

    /// @custom:function claim
    /// @notice User shouldn't be able to claim tokens before presale started
    function testFuzz_Claim_RevertWhen_PresaleNotStarted(address _user) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.claim();
    }
}

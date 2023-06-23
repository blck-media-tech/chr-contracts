// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.v2.helper.t.sol";
import "./CHRPresale.v2.timeIndependent.t.sol";

/// @title Test for Chancer presale in case current timestamp is after presale end and claim is not yet started
contract CHRPresaleV2Test_AfterPresale is CHRPresaleV2Test_TimeIndependent {
    /// @notice Expected state - contract deployed, presale ended, claim not started
    function setUp() public virtual override {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        presaleContract = new CHRPresaleV2Harness(
            address(tokenContract),
            address(mockAggregator),
            address(mockBUSD),
            address(presaleContractV1),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        vm.warp(saleEndTime);
    }

    /// @notice Ensure that test initial state was set up correctly
    function testFuzz_SetUpState(address _user, uint256 _amount, address _owner) public virtual override {
        helper_simulatePresaleV1AndSync(_user, _amount, _owner);
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.busdToken()), address(mockBUSD));
        assertEq(address(presaleContract.presaleV1()), address(presaleContractV1));
        assertEq(presaleContract.totalTokensSold(), presaleContractV1.totalTokensSold());
        assertEq(presaleContract.saleStartTime(), block.timestamp - timeDelay);
        assertEq(presaleContract.saleEndTime(), block.timestamp);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), presaleContractV1.currentStage());
        assertEq(presaleContract.purchasedTokens(_user), _amount);
    }

    /// @custom:function buyWithBNB
    /// @notice User shouldn't be able to buy with BNB after presale ended
    function testFuzz_BuyWithBnb_RevertWhen_PresaleEnded(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithBnb(_amount, _referrerId);
    }

    /// @custom:function buyWithBUSD
    /// @notice User shouldn't be able to buy with BUSD after presale ended
    function testFuzz_BuyWithBUSD_RevertWhen_PresaleEnded(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithBUSD(_amount, _referrerId);
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

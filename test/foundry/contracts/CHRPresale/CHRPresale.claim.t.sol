// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";
import "./CHRPresale.timeIndependent.t.sol";

/// @title Test for Chancer presale in case current timestamp is after presale end and claim was started
contract CHRPresaleTest_Claim is CHRPresaleTest_TimeIndependent {
    /// @notice Expected state - contract deployed, preasle ended, claim started
    function setUp() public virtual override {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        uint256 claimStartTime = block.timestamp + timeDelay * 3;
        presaleContract = new CHRPresaleHarness(
            address(tokenContract),
            address(mockAggregator),
            address(mockUSDT),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        presaleContract.configureClaim(claimStartTime);

        vm.warp(claimStartTime);
    }

    /// @notice Ensure that test initial state was set up correctly
    function test_SetUpState() public override {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp - timeDelay * 2);
        assertEq(presaleContract.saleEndTime(), block.timestamp - timeDelay);
        assertEq(presaleContract.claimStartTime(), block.timestamp);
        assertEq(presaleContract.currentStage(), 0);
    }

    /// @custom:function buyWithETH
    /// @notice User shouldn't be able to buy with ETH after presale ended
    function testFuzz_BuyWithEth_RevertWhen_ClaimStarted(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithEth(_amount, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice User shouldn't be able to buy with USDT after presale ended
    function testFuzz_BuyWithUSDT_RevertWhen_ClaimStarted(uint256 _amount, address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount, _referrerId);
    }

    /// @custom:function claim
    /// @notice Expected result:
    ///         - tokens transferred from presale contract to user
    ///         - TokensClaimed event emitted
    ///         - user marked as claimed
    function testFuzz_Claim(address _user, uint256 _amount, address _owner, uint256 _referrerId) public {
        vm.assume(_user != address(0));
        vm.assume(_owner >= address(10));
        vm.assume(_owner != _user);
        vm.assume(_owner.code.length == 0);
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        helper_purchaseTokens(_user, _amount, _owner, _referrerId);

        uint256 userBalanceBefore = tokenContract.balanceOf(_user);
        uint256 contractBalanceBefore = tokenContract.balanceOf(address(presaleContract));

        assertFalse(presaleContract.hasClaimed(_user));

        vm.expectEmit(true, true, true, true);
        emit TokensClaimed(_user, _amount * 1e18, block.timestamp);

        vm.prank(_user);
        presaleContract.claim();

        assertEq(tokenContract.balanceOf(_user), userBalanceBefore + _amount * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), contractBalanceBefore - _amount * 1e18);
        assertTrue(presaleContract.hasClaimed(_user));
    }

    /// @custom:function claim
    /// @notice Execution should be reverted if user tries to claim second time
    function testFuzz_Claim_RevertWhen_ClaimingSecondTime(
        address _user,
        uint256 _amount,
        address _owner,
        uint256 _referrerId
    ) public {
        vm.assume(_user != address(0));
        vm.assume(_owner >= address(10));
        vm.assume(_owner != _user);
        vm.assume(_owner.code.length == 0);
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        helper_purchaseTokens(_user, _amount, _owner, _referrerId);

        uint256 userBalanceBefore = tokenContract.balanceOf(_user);
        uint256 contractBalanceBefore = tokenContract.balanceOf(address(presaleContract));

        assertFalse(presaleContract.hasClaimed(_user));

        vm.expectEmit(true, true, true, true);
        emit TokensClaimed(_user, _amount * 1e18, block.timestamp);

        vm.prank(_user);
        presaleContract.claim();

        assertEq(tokenContract.balanceOf(_user), userBalanceBefore + _amount * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), contractBalanceBefore - _amount * 1e18);
        assertTrue(presaleContract.hasClaimed(_user));

        vm.expectRevert(abi.encodeWithSelector(AlreadyClaimed.selector));

        vm.prank(_user);
        presaleContract.claim();
    }

    /// @custom:function claim
    /// @notice Execution should be reverted if user doesn't purchase tokens
    function testFuzz_Claim_RevertWhen_NoTokensPurchased(address _user) public {
        vm.expectRevert(abi.encodeWithSelector(NothingToClaim.selector));

        vm.prank(_user);
        presaleContract.claim();
    }
}

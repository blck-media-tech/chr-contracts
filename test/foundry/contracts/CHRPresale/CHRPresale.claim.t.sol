// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";

contract CHRPresaleTest_Claim is Test, CHRPresaleHelper, IPresale {
    uint256 timeDelay = 1 days;

    function setUp() public {
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

    function test_SetUpState() public {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp - timeDelay * 2);
        assertEq(presaleContract.saleEndTime(), block.timestamp - timeDelay);
        assertEq(presaleContract.claimStartTime(), block.timestamp);
        assertEq(presaleContract.currentStage(), 0);
    }

    function testFuzz_BuyWithEth_RevertWhen_ClaimStarted(uint256 _amount, address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithEth(_amount);
    }

    function testFuzz_BuyWithUSDT_RevertWhen_ClaimStarted(uint256 _amount, address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount);
    }

    function testFuzz_Claim(address _user, uint256 _amount, address _owner) public {
        vm.assume(_user != address(0));
        vm.assume(_owner >= address(10));
        vm.assume(_owner != _user);
        vm.assume(_owner.code.length == 0);
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        helper_purchaseTokens(_user, _amount, _owner);

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

    function testFuzz_Claim_RevertWhen_ClaimingSecondTime(address _user, uint256 _amount, address _owner) public {
        vm.assume(_user != address(0));
        vm.assume(_owner >= address(10));
        vm.assume(_owner != _user);
        vm.assume(_owner.code.length == 0);
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        helper_purchaseTokens(_user, _amount, _owner);

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

        vm.expectRevert(
            abi.encodeWithSelector(AlreadyClaimed.selector)
        );

        vm.prank(_user);
        presaleContract.claim();
    }

    function testFuzz_Claim_RevertWhen_NoTokensPurchased(address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(NothingToClaim.selector)
        );

        vm.prank(_user);
        presaleContract.claim();
    }
}

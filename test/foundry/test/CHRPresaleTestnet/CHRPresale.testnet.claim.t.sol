// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.testnet.helper.t.sol";
import "../../contracts/CHRPresale/CHRPresale.claim.t.sol";

contract CHRPresaleTestnetTest_Claim is CHRPresaleTestnetHelper, CHRPresaleTest_Claim {

    function setUp() public override {
        uint256 saleStartTime = block.timestamp + timeDelay;
        uint256 saleEndTime = block.timestamp + timeDelay * 2;
        uint256 claimStartTime = block.timestamp + timeDelay * 3;
        presaleContractTestnet = new CHRPresaleTestnetHarness(
            address(tokenContract),
            address(mockAggregator),
            address(mockUSDT),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );
        presaleContract = CHRPresaleHarness(address(presaleContractTestnet));

        presaleContractTestnet.configureClaim(claimStartTime);

        vm.warp(claimStartTime);
    }

    function testFuzz_T_Reset(address _user, uint256 _amount) public {
        vm.assume(type(uint256).max - tokenContract.totalSupply() > _amount);

        helper_prepareToClaim(_user, _amount);

        assertEq(presaleContractTestnet.purchasedTokens(_user), _amount);
        assertFalse(presaleContractTestnet.hasClaimed(_user));

        helper_simulateClaim(_user);

        assertEq(presaleContractTestnet.purchasedTokens(_user), _amount);
        assertTrue(presaleContractTestnet.hasClaimed(_user));

        vm.prank(_user);
        presaleContractTestnet.t_resetUser(_user);

        assertEq(presaleContractTestnet.purchasedTokens(_user), 0);
        assertFalse(presaleContractTestnet.hasClaimed(_user));
    }

    function testFuzz_T_ClaimAndReset(address _user, uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_user != address(0));
        vm.assume(type(uint256).max - tokenContract.totalSupply() > _amount);

        helper_prepareToClaim(_user, _amount);

        vm.prank(_user);
        presaleContractTestnet.t_claimAndReset();

        assertEq(presaleContractTestnet.purchasedTokens(_user), 0);
        assertFalse(presaleContractTestnet.hasClaimed(_user));
    }
//
//    function testFuzz_Claim(address _user, uint256 _amount, address _owner) public {
//        vm.assume(_user != address(0));
//        vm.assume(_owner >= address(10));
//        vm.assume(_owner != _user);
//        vm.assume(_owner.code.length == 0);
//        vm.assume(_amount > 0);
//        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
//        helper_purchaseTokens(_user, _amount, _owner);
//
//        uint256 userBalanceBefore = tokenContract.balanceOf(_user);
//        uint256 contractBalanceBefore = tokenContract.balanceOf(address(presaleContract));
//
//        assertFalse(presaleContract.hasClaimed(_user));
//
//        vm.expectEmit(true, true, true, true);
//        emit TokensClaimed(_user, _amount * 1e18, block.timestamp);
//
//        vm.prank(_user);
//        presaleContract.claim();
//
//        assertEq(tokenContract.balanceOf(_user), userBalanceBefore + _amount * 1e18);
//        assertEq(tokenContract.balanceOf(address(presaleContract)), contractBalanceBefore - _amount * 1e18);
//        assertTrue(presaleContract.hasClaimed(_user));
//    }
//
//    function testFuzz_Claim_RevertWhen_ClaimingSecondTime(address _user, uint256 _amount, address _owner) public {
//        vm.assume(_user != address(0));
//        vm.assume(_owner >= address(10));
//        vm.assume(_owner != _user);
//        vm.assume(_owner.code.length == 0);
//        vm.assume(_amount > 0);
//        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
//        helper_purchaseTokens(_user, _amount, _owner);
//
//        uint256 userBalanceBefore = tokenContract.balanceOf(_user);
//        uint256 contractBalanceBefore = tokenContract.balanceOf(address(presaleContract));
//
//        assertFalse(presaleContract.hasClaimed(_user));
//
//        vm.expectEmit(true, true, true, true);
//        emit TokensClaimed(_user, _amount * 1e18, block.timestamp);
//
//        vm.prank(_user);
//        presaleContract.claim();
//
//        assertEq(tokenContract.balanceOf(_user), userBalanceBefore + _amount * 1e18);
//        assertEq(tokenContract.balanceOf(address(presaleContract)), contractBalanceBefore - _amount * 1e18);
//        assertTrue(presaleContract.hasClaimed(_user));
//
//        vm.expectRevert(
//            abi.encodeWithSelector(AlreadyClaimed.selector)
//        );
//
//        vm.prank(_user);
//        presaleContract.claim();
//    }
//
//    function testFuzz_Claim_RevertWhen_NoTokensPurchased(address _user) public {
//        vm.expectRevert(
//            abi.encodeWithSelector(NothingToClaim.selector)
//        );
//
//        vm.prank(_user);
//        presaleContract.claim();
//    }
}

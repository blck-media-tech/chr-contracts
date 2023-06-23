// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.eth.helper.t.sol";
import "./CHRPresale.eth.timeIndependent.t.sol";

/// @title Test for Chancer presale in case current timestamp is when presale in progress
contract CHRPresaleETHTest_Presale is CHRPresaleETHTest_TimeIndependent {
    /// @notice Expected state - contract deployed, preasle started, claim not started
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

        vm.warp(saleStartTime);
    }

    /// @notice Ensure that test initial state was set up correctly
    function test_SetUpState() public override {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp);
        assertEq(presaleContract.saleEndTime(), block.timestamp + timeDelay);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), 0);
    }

    /// @custom:function buyWithETH
    /// @notice Expected result:
    ///         - amount of purchased buy user tokens was increased
    ///         - TokensBought event emitted with 0 referal id
    ///         - sent ETH were transferred to presale contract owner
    function testFuzz_BuyWithEth(uint256 _amount, address _user, address _owner, uint256 _referrerId) public {
        vm.assume(address(_owner) != address(0));
        vm.assume(_owner != _user);
        vm.assume(_owner >= address(10));
        vm.assume(_owner.code.length == 0);
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        vm.prank(presaleContract.owner());
        presaleContract.transferOwnership(_owner);

        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);
        deal(_user, priceInETH);

        uint256 balanceUserBefore = address(_user).balance;
        uint256 balanceOwnerBefore = address(_owner).balance;
        uint256 tokensPurchasedBefore = presaleContract.purchasedTokens(_user);
        uint256 totalTokensSoldBefore = presaleContract.totalTokensSold();

        vm.expectEmit(true, true, true, true);
        emit TokensBought(_user, "ETH", _amount, priceInUSDT, priceInETH, _referrerId, block.timestamp);

        vm.prank(_user);
        presaleContract.buyWithEth{ value: priceInETH }(_amount, _referrerId);

        assertEq(address(_user).balance, balanceUserBefore - priceInETH);
        assertEq(address(_owner).balance, balanceOwnerBefore + priceInETH);
        assertEq(presaleContract.purchasedTokens(_user), tokensPurchasedBefore + _amount);
        assertEq(presaleContract.totalTokensSold(), totalTokensSoldBefore + _amount);
    }

    /// @custom:function buyWithETH
    /// @notice Execution should be reverted if trying to purchase 0 tokens
    function testFuzz_BuyWithEth_RevertOn_PurchasingZeroTokens(address _user, uint256 _referrerId) public {
        vm.expectRevert(abi.encodeWithSelector(BuyAtLeastOneToken.selector));

        vm.prank(_user);
        presaleContract.buyWithEth(0, _referrerId);
    }

    /// @custom:function buyWithETH
    /// @notice Execution should be reverted if trying to purchase amount of tokens that overflows presale limit
    function testFuzz_BuyWithEth_RevertOn_PurchasingMoreTokensThanPresaleLimit(
        address _user,
        uint256 _amount,
        uint256 _referrerId
    ) public {
        vm.assume(_amount > limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        vm.expectRevert(
            abi.encodeWithSelector(
                PresaleLimitExceeded.selector,
                limitPerStage[presaleContract.MAX_STAGE_INDEX()] - presaleContract.totalTokensSold()
            )
        );

        vm.prank(_user);
        presaleContract.buyWithEth(_amount, _referrerId);
    }

    /// @custom:function buyWithETH
    /// @notice Execution should be reverted if contract is paused
    function testFuzz_BuyWithEth_RevertWhen_ContractPaused(address _user, uint256 _amount, uint256 _referrerId) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.pause();

        vm.expectRevert("Pausable: paused");

        vm.prank(_user);
        presaleContract.buyWithEth(_amount, _referrerId);
    }

    /// @custom:function buyWithETH
    /// @notice Execution should be reverted if user blacklisted
    function testFuzz_BuyWithEth_RevertOn_BlacklistedUserCall(
        address _user,
        uint256 _amount,
        uint256 _referrerId
    ) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        address[] memory addressesToBlacklist = new address[](1);
        addressesToBlacklist[0] = _user;
        presaleContract.addToBlacklist(addressesToBlacklist);

        vm.expectRevert(abi.encodeWithSelector(AddressBlacklisted.selector));

        vm.prank(_user);
        presaleContract.buyWithEth(_amount, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice Expected result:
    ///         - amount of purchased buy user tokens was increased
    ///         - TokensBought event emitted with passed referal id
    ///         - sent ETH were transferred to presale contract owner
    function testFuzz_BuyWithUSDT(address _user, uint256 _amount, uint256 _referrerId) public {
        vm.assume(_user != address(0));
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);
        deal(address(mockUSDT), _user, priceInUSDT, true);

        uint256 balanceUserBefore = mockUSDTWrapped.balanceOf(_user);
        uint256 balanceOwnerBefore = mockUSDTWrapped.balanceOf(presaleContract.owner());
        uint256 tokensPurchasedBefore = presaleContract.purchasedTokens(_user);

        uint256 totalTokensSoldBefore = presaleContract.totalTokensSold();

        vm.prank(_user);
        address(mockUSDT).call(
            abi.encodeWithSignature("approve(address,uint256)", address(presaleContract), priceInUSDT)
        );

        vm.expectEmit(true, true, true, true);
        emit TokensBought(_user, "USDT", _amount, priceInUSDT, priceInETH, _referrerId, block.timestamp);

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount, _referrerId);

        assertEq(mockUSDTWrapped.balanceOf(_user), balanceUserBefore - priceInUSDT);
        assertEq(mockUSDTWrapped.balanceOf(presaleContract.owner()), balanceOwnerBefore + priceInUSDT);
        assertEq(presaleContract.purchasedTokens(_user), tokensPurchasedBefore + _amount);
        assertEq(presaleContract.totalTokensSold(), totalTokensSoldBefore + _amount);
    }

    /// @custom:function buyWithUSDT
    /// @notice Execution should be reverted if trying to purchase 0 tokens
    function testFuzz_BuyWithUSDT_RevertOn_PurchasingZeroTokens(address _user, uint256 _referrerId) public {
        vm.assume(_user != address(0));

        vm.expectRevert(abi.encodeWithSelector(BuyAtLeastOneToken.selector));

        vm.prank(_user);
        presaleContract.buyWithUSDT(0, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice Execution should be reverted if trying to purchase amount of tokens that overflows presale limit
    function testFuzz_BuyWithUSDT_RevertOn_PurchasingMoreTokensThanPresaleLimit(
        address _user,
        uint256 _amount,
        uint256 _referrerId
    ) public {
        vm.assume(_amount > limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        vm.expectRevert(
            abi.encodeWithSelector(
                PresaleLimitExceeded.selector,
                limitPerStage[presaleContract.MAX_STAGE_INDEX()] - presaleContract.totalTokensSold()
            )
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice Execution should be reverted if provided allowance is not enough
    function testFuzz_BuyWithUSDT_RevertOn_NotEnoughAllowance(
        address _user,
        uint256 _amount,
        uint256 _referrerId
    ) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);

        vm.expectRevert(abi.encodeWithSelector(NotEnoughAllowance.selector, 0, priceInUSDT));

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice Execution should be reverted if contract is paused
    function testFuzz_BuyWithUSDT_RevertWhen_ContractPaused(
        address _user,
        uint256 _amount,
        uint256 _referrerId
    ) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);
        presaleContract.pause();

        vm.expectRevert("Pausable: paused");

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount, _referrerId);
    }

    /// @custom:function buyWithUSDT
    /// @notice Execution should be reverted if user blacklisted
    function testFuzz_BuyWithUSDT_RevertOn_BlacklistedUserCall(
        address _user,
        uint256 _amount,
        uint256 _referrerId
    ) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        address[] memory addressesToBlacklist = new address[](1);
        addressesToBlacklist[0] = _user;
        presaleContract.addToBlacklist(addressesToBlacklist);

        vm.expectRevert(abi.encodeWithSelector(AddressBlacklisted.selector));

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount, _referrerId);
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
    /// @notice Execution should be reverted if claim is not started
    function testFuzz_Claim_RevertWhen_PresaleInProgress(address _user) public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTimeframe.selector));

        vm.prank(_user);
        presaleContract.claim();
    }
}

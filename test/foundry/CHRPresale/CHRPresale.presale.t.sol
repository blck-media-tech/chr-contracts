// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";

contract CHRPresaleTest_Presale is Test, CHRPresaleHelper, IPresale {
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

        vm.warp(saleStartTime);
    }

    function test_SetUpState() public {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp);
        assertEq(presaleContract.saleEndTime(), block.timestamp + timeDelay);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), 0);
    }

    function testFuzz_BuyWithEth(uint256 _amount, address _user, address _owner) public {
        vm.assume(address(_owner) != address(0));
        vm.assume(_owner != _user);
        vm.assume(_owner.code.length == 0);
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        vm.prank(presaleContract.owner());
        presaleContract.transferOwnership(_owner);

        uint256 ethCost = presaleContract.getPriceInETH(_amount);
        deal(_user, ethCost);

        uint256 balanceUserBefore = address(_user).balance;
        uint256 balanceOwnerBefore = address(_owner).balance;
        uint256 tokensPurchasedBefore = presaleContract.purchasedTokens(_user);
        uint256 totalTokensSoldBefore = presaleContract.totalTokensSold();

        vm.expectEmit(true, true, true, true);
        emit TokensBought(
            _user,
            _amount,
            presaleContract.getPriceInUSDT(_amount),
            presaleContract.getPriceInETH(_amount),
            block.timestamp
        );

        vm.prank(_user);
        presaleContract.buyWithEth{value : ethCost}(_amount);

        assertEq(address(_user).balance, balanceUserBefore - ethCost);
        assertEq(address(_owner).balance, balanceOwnerBefore + ethCost);
        assertEq(presaleContract.purchasedTokens(_user), tokensPurchasedBefore + _amount * 1e18);
        assertEq(presaleContract.totalTokensSold(), totalTokensSoldBefore + _amount);
    }

    function testFuzz_BuyWithEth_RevertWhen_PurchasingZeroTokens(address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(BuyAtLeastOneToken.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithEth(0);
    }

    function testFuzz_BuyWithEth_RevertWhen_PurchasingMoreTokensThanPresaleLimit(address _user, uint256 _amount) public {
        vm.assume(_amount > limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        vm.expectRevert(
            abi.encodeWithSelector(PresaleLimitExceeded.selector, limitPerStage[presaleContract.MAX_STAGE_INDEX()] - presaleContract.totalTokensSold())
        );

        vm.prank(_user);
        presaleContract.buyWithEth(_amount);
    }

    function testFuzz_BuyWithUSDT(address _user, uint256 _amount) public {
        vm.assume(_user != address(0));
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        uint256 usdtCost = presaleContract.getPriceInUSDT(_amount);
        deal(address(mockUSDT), _user, usdtCost, true);

        uint256 balanceUserBefore = mockUSDTWrapped.balanceOf(_user);
        uint256 balanceOwnerBefore = mockUSDTWrapped.balanceOf(presaleContract.owner());
        uint256 tokensPurchasedBefore = presaleContract.purchasedTokens(_user);

        uint256 totalTokensSoldBefore = presaleContract.totalTokensSold();

        vm.prank(_user);
        address(mockUSDT).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                    address(presaleContract),
                    usdtCost
            )
        );

        vm.expectEmit(true, true, true, true);
        emit TokensBought(
            _user,
            _amount,
            presaleContract.getPriceInUSDT(_amount),
            presaleContract.getPriceInETH(_amount),
            block.timestamp
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount);

        assertEq(mockUSDTWrapped.balanceOf(_user), balanceUserBefore - usdtCost);
        assertEq(mockUSDTWrapped.balanceOf(presaleContract.owner()), balanceOwnerBefore + usdtCost);
        assertEq(presaleContract.purchasedTokens(_user), tokensPurchasedBefore + _amount * 1e18);
        assertEq(presaleContract.totalTokensSold(), totalTokensSoldBefore + _amount);
    }

    function testFuzz_Claim(address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.claim();
    }
}

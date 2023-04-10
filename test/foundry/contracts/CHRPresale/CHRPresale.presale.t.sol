// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";

contract CHRPresaleTest_Presale is Test, CHRPresaleHelper, IPresale {

    function setUp() public virtual {
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
        emit TokensBought(
            _user,
            _amount,
            priceInUSDT,
            priceInETH,
            block.timestamp
        );



        vm.prank(_user);
        presaleContract.buyWithEth{value : priceInETH}(_amount);

        assertEq(address(_user).balance, balanceUserBefore - priceInETH);
        assertEq(address(_owner).balance, balanceOwnerBefore + priceInETH);
        assertEq(presaleContract.purchasedTokens(_user), tokensPurchasedBefore + _amount * 1e18);
        assertEq(presaleContract.totalTokensSold(), totalTokensSoldBefore + _amount);
    }

    function testFuzz_BuyWithEth_RevertOn_PurchasingZeroTokens(address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(BuyAtLeastOneToken.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithEth(0);
    }

    function testFuzz_BuyWithEth_RevertOn_PurchasingMoreTokensThanPresaleLimit(address _user, uint256 _amount) public {
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

        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);
        deal(address(mockUSDT), _user, priceInUSDT, true);

        uint256 balanceUserBefore = mockUSDTWrapped.balanceOf(_user);
        uint256 balanceOwnerBefore = mockUSDTWrapped.balanceOf(presaleContract.owner());
        uint256 tokensPurchasedBefore = presaleContract.purchasedTokens(_user);

        uint256 totalTokensSoldBefore = presaleContract.totalTokensSold();

        vm.prank(_user);
        address(mockUSDT).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(presaleContract),
                priceInUSDT
            )
        );

        vm.expectEmit(true, true, true, true);
        emit TokensBought(
            _user,
            _amount,
            priceInUSDT,
            priceInETH,
            block.timestamp
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount);

        assertEq(mockUSDTWrapped.balanceOf(_user), balanceUserBefore - priceInUSDT);
        assertEq(mockUSDTWrapped.balanceOf(presaleContract.owner()), balanceOwnerBefore + priceInUSDT);
        assertEq(presaleContract.purchasedTokens(_user), tokensPurchasedBefore + _amount * 1e18);
        assertEq(presaleContract.totalTokensSold(), totalTokensSoldBefore + _amount);
    }

    function testFuzz_BuyWithUSDT_RevertOn_PurchasingZeroTokens(address _user) public {
        vm.assume(_user != address(0));

        vm.expectRevert(
            abi.encodeWithSelector(BuyAtLeastOneToken.selector)
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(0);
    }

    function testFuzz_BuyWithUSDT_RevertOn_PurchasingMoreTokensThanPresaleLimit(address _user, uint256 _amount) public {
        vm.assume(_amount > limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        vm.expectRevert(
            abi.encodeWithSelector(PresaleLimitExceeded.selector, limitPerStage[presaleContract.MAX_STAGE_INDEX()] - presaleContract.totalTokensSold())
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount);
    }

    function testFuzz_BuyWithUSDT_RevertOn_NotEnoughAllowance(address _user, uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.assume(_amount <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);

        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);

        vm.expectRevert(
            abi.encodeWithSelector(NotEnoughAllowance.selector, 0, priceInUSDT)
        );

        vm.prank(_user);
        presaleContract.buyWithUSDT(_amount);
    }

    function testFuzz_Claim_RevertWhen_PresaleInProgress(address _user) public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimeframe.selector)
        );

        vm.prank(_user);
        presaleContract.claim();
    }
}

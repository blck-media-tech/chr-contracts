// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.helper.t.sol";

contract CHRPresaleTest_TimeIndependent is Test, CHRPresaleHelper, IPresale {
    event Paused(address account);
    event Unpaused(address account);

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
    }

    function test_SetUpState() public {
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.usdtToken()), address(mockUSDT));
        assertEq(presaleContract.totalTokensSold(), 0);
        assertEq(presaleContract.saleStartTime(), block.timestamp + timeDelay);
        assertEq(presaleContract.saleEndTime(), block.timestamp + timeDelay * 2);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), 0);
        assertEq(presaleContract.paused(), false);
    }

    function test_Pause() public {
        vm.expectEmit(true, true, true, true);
        emit Paused(address(this));

        presaleContract.pause();
        assertEq(presaleContract.paused(), true);
    }

    function test_Pause_RevertWhen_AlreadyPaused() public {
        presaleContract.pause();
        assertEq(presaleContract.paused(), true);

        vm.expectRevert("Pausable: paused");

        presaleContract.pause();
        assertEq(presaleContract.paused(), true);
    }

    function testFuzz_Pause_RevertOn_NonOwnerCall(address _nonOwner) public {
        vm.assume(_nonOwner != address(this));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.pause();
    }

    function test_Unpause() public {
        presaleContract.pause();
        assertEq(presaleContract.paused(), true);

        vm.expectEmit(true, true, true, true);
        emit Unpaused(address(this));

        presaleContract.unpause();
        assertEq(presaleContract.paused(), false);
    }

    function test_Unpause_RevertWhen_NonPaused() public {
        vm.expectRevert("Pausable: not paused");

        presaleContract.unpause();
    }

    function testFuzz_Unpause_RevertOn_NonOwnerCall(address _nonOwner) public {
        presaleContract.pause();
        assertEq(presaleContract.paused(), true);

        vm.assume(_nonOwner != address(this));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.unpause();
    }

    function testFuzz_AddToBlacklist(address[] calldata _users) public {
        presaleContract.addToBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), true);
        }
    }

    function testFuzz_AddToBlacklist_RevertOn_NonOwnerCall(address[] calldata _users, address _nonOwner) public {
        vm.assume(_nonOwner != address(this));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.addToBlacklist(_users);
    }

    function testFuzz_RemoveFromBlacklist(address[] calldata _users) public {
        presaleContract.addToBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), true);
        }

        presaleContract.removeFromBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), false);
        }
    }

    function testFuzz_RemoveFromBlacklist_RevertOn_NonOwnerCall(address[] calldata _users, address _nonOwner) public {
        vm.assume(_nonOwner != address(this));

        presaleContract.addToBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), true);
        }

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.addToBlacklist(_users);
    }

    function testFuzz_rescueERC20(uint256 _amount) public {
        ERC20 token = new ERC20("Test ERC20", "TERC");
        assertEq(token.balanceOf(address(presaleContract)), 0);
        deal(address(token), address(presaleContract), _amount, true);
        assertEq(token.balanceOf(address(presaleContract)), _amount);
        assertEq(token.balanceOf(address(this)), 0);

        presaleContract.rescueERC20(address(token), _amount);

        assertEq(token.balanceOf(address(presaleContract)), 0);
        assertEq(token.balanceOf(address(this)), _amount);
    }

    function testFuzz_rescueERC20_RevertOn_NonOwnerCall(uint256 _amount, address _nonOwner) public {
        ERC20 token = new ERC20("Test ERC20", "TERC");
        assertEq(token.balanceOf(address(presaleContract)), 0);
        deal(address(token), address(presaleContract), _amount, true);
        assertEq(token.balanceOf(address(presaleContract)), _amount);
        assertEq(token.balanceOf(address(this)), 0);

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.rescueERC20(address(token), _amount);
    }

    function testFuzz_ConfigureSaleTimeframe(uint256 _saleStartTime, uint256 _saleEndTime) public {
        vm.expectEmit(true, true, true, true);
        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);

        presaleContract.configureSaleTimeframe(_saleStartTime, _saleEndTime);

        assertEq(presaleContract.saleStartTime(), _saleStartTime);
        assertEq(presaleContract.saleEndTime(), _saleEndTime);
    }

    function testFuzz_ConfigureSaleTimeframe_RevertOn_NonOwnerCall(uint256 _saleStartTime, uint256 _saleEndTime, address _nonOwner) public {
        vm.assume(_nonOwner != address(presaleContract.owner()));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.configureSaleTimeframe(_saleStartTime, _saleEndTime);
    }

    function testFuzz_ConfigureClaim(uint256 _totalTokensSold, uint256 _claimStartTime) public {
        vm.assume(type(uint256).max / 1e18 > _totalTokensSold);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        deal(address(tokenContract), address(presaleContract), _totalTokensSold * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), _totalTokensSold * 1e18);

        presaleContract.configureClaim(_claimStartTime);
        assertEq(presaleContract.claimStartTime(), _claimStartTime);
    }

    function testFuzz_ConfigureClaim_RevertOn_NonOwnerCall(uint256 _totalTokensSold, uint256 _claimStartTime, address _nonOwner) public {
        vm.assume(type(uint256).max / 1e18 > _totalTokensSold);
        vm.assume(_nonOwner != presaleContract.owner());
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        deal(address(tokenContract), address(presaleContract), _totalTokensSold * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), _totalTokensSold * 1e18);

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.configureClaim(_claimStartTime);
    }

    function test_GetCurrentPrice() public {
        for (uint8 i = 0; i <= presaleContract.MAX_STAGE_INDEX(); i += 1) {
            presaleContract.workaround_setCurrentStage(i);
            assertEq(presaleContract.currentStage(), i);
            assertEq(presaleContract.getCurrentPrice(), pricePerStage[i]);
        }
    }

    function testFuzz_GetSoldOnCurrentStage(uint256 _totalTokensSold) public {
        vm.assume(_totalTokensSold <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        uint8 currentStage = presaleContract.exposed_getStageByTotalSoldAmount();
        presaleContract.workaround_setCurrentStage(currentStage);

        uint256 soldOnCurrentStage = _totalTokensSold - (currentStage == 0 ? 0 : limitPerStage[currentStage - 1]);
        assertEq(soldOnCurrentStage, presaleContract.getSoldOnCurrentStage());
    }

    function testFuzz_TotalSoldPrice(uint256 _totalTokensSold) public {
        vm.assume(_totalTokensSold <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        uint8 currentStage = presaleContract.exposed_getStageByTotalSoldAmount();
        presaleContract.workaround_setCurrentStage(currentStage);

        uint256 sum = 0;

        for (uint256 i = 0; i < currentStage; i += 1) {
            sum += pricePerStage[i] * (limitPerStage[i] - (i == 0 ? 0 : limitPerStage[i - 1]));
        }

        sum += pricePerStage[currentStage] * (_totalTokensSold - (currentStage == 0 ? 0 : limitPerStage[currentStage - 1]));

        assertEq(presaleContract.totalSoldPrice(), sum);
    }

    function testFuzz_SendValue(address payable _user, uint256 _amount) public {
        vm.assume(_user.code.length == 0);
        vm.assume(_user >= address(10));
        uint256 balanceBefore = address(_user).balance;
        deal(address(presaleContract), _amount);

        presaleContract.exposed_sendValue(_user, _amount);
        assertEq(address(_user).balance, balanceBefore + _amount);
    }

    function testFuzz_GetStageByTotalSoldAmount(uint256 _totalTokensSold) public {
        vm.assume(_totalTokensSold <= pricePerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);

        uint8 stageIndex = presaleContract.MAX_STAGE_INDEX();
        while (stageIndex > 0) {
            if (limitPerStage[stageIndex - 1] <= _totalTokensSold)
                break;
            stageIndex -= 1;
        }

        assertEq(presaleContract.exposed_getStageByTotalSoldAmount(), stageIndex);
    }
}

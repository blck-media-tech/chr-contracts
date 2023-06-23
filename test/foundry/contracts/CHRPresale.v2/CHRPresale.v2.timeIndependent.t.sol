// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/interfaces/IPresale.sol";
import "./CHRPresale.v2.helper.t.sol";

/// @title Test for Chancer presale functions that should be independent from time they are executed
contract CHRPresaleV2Test_TimeIndependent is CHRPresaleV2Helper, IPresale {
    event Paused(address account);
    event Unpaused(address account);

    /// @notice Expected state - contract deployed
    function setUp() public virtual {
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
    }

    /// @notice Ensure that test initial state was set up correctly
    function testFuzz_SetUpState(address _user, uint256 _amount, address _owner) public virtual {
        helper_simulatePresaleV1AndSync(_user, _amount, _owner);
        assertEq(address(presaleContract.saleToken()), address(tokenContract));
        assertEq(address(presaleContract.oracle()), address(mockAggregator));
        assertEq(address(presaleContract.busdToken()), address(mockBUSD));
        assertEq(address(presaleContract.presaleV1()), address(presaleContractV1));
        assertEq(presaleContract.totalTokensSold(), presaleContractV1.totalTokensSold());
        assertEq(presaleContract.saleStartTime(), block.timestamp + timeDelay);
        assertEq(presaleContract.saleEndTime(), block.timestamp + timeDelay * 2);
        assertEq(presaleContract.claimStartTime(), 0);
        assertEq(presaleContract.currentStage(), presaleContractV1.currentStage());
        assertEq(presaleContract.paused(), false);
        assertEq(presaleContract.purchasedTokens(_user), _amount);
    }

    /// @custom:function pause
    /// @notice Expected result:
    ///         - contract should be paused
    ///         - Paused event emitted
    function test_Pause() public {
        vm.expectEmit(true, true, true, true);
        emit Paused(address(this));

        presaleContract.pause();
        assertEq(presaleContract.paused(), true);
    }

    /// @custom:function pause
    /// @notice Should be reverted if contract already paused
    function test_Pause_RevertWhen_AlreadyPaused() public {
        presaleContract.pause();
        assertEq(presaleContract.paused(), true);

        vm.expectRevert("Pausable: paused");

        presaleContract.pause();
        assertEq(presaleContract.paused(), true);
    }

    /// @custom:function pause
    /// @notice Should be reverted if caller is not the owner
    function testFuzz_Pause_RevertOn_NonOwnerCall(address _nonOwner) public {
        vm.assume(_nonOwner != address(this));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.pause();
    }

    /// @custom:function unpause
    /// @notice Expected result:
    ///         - contract should be unpaused
    ///         - Unpaused event emitted
    function test_Unpause() public {
        presaleContract.pause();
        assertEq(presaleContract.paused(), true);

        vm.expectEmit(true, true, true, true);
        emit Unpaused(address(this));

        presaleContract.unpause();
        assertEq(presaleContract.paused(), false);
    }

    /// @custom:function unpause
    /// @notice Should be reverted if contract already unpaused
    function test_Unpause_RevertWhen_NonPaused() public {
        vm.expectRevert("Pausable: not paused");

        presaleContract.unpause();
    }

    /// @custom:function unpause
    /// @notice Should be reverted if caller is not the owner
    function testFuzz_Unpause_RevertOn_NonOwnerCall(address _nonOwner) public {
        presaleContract.pause();
        assertEq(presaleContract.paused(), true);

        vm.assume(_nonOwner != address(this));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.unpause();
    }

    /// @custom:function addToBlacklist
    /// @notice Expected result:
    ///         - all passed addresses added to blacklist
    function testFuzz_AddToBlacklist(address[] calldata _users) public {
        for (uint256 i = 0; i < _users.length; i += 1) {
            vm.expectEmit(true, true, true, true);
            emit AddedToBlacklist(_users[i], block.timestamp);
        }

        presaleContract.addToBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), true);
        }
    }

    /// @custom:function addToBlacklist
    /// @notice Should be reverted if caller is not the owner
    function testFuzz_AddToBlacklist_RevertOn_NonOwnerCall(address[] calldata _users, address _nonOwner) public {
        vm.assume(_nonOwner != address(this));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.addToBlacklist(_users);
    }

    /// @custom:function removeFromBlacklist
    /// @notice Expected result:
    ///         - all passed addresses removed from blacklist
    function testFuzz_RemoveFromBlacklist(address[] calldata _users) public {
        presaleContract.addToBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), true);
            vm.expectEmit(true, true, true, true);
            emit RemovedFromBlacklist(_users[i], block.timestamp);
        }

        presaleContract.removeFromBlacklist(_users);

        for (uint256 i = 0; i < _users.length; i += 1) {
            assertEq(presaleContract.blacklist(_users[i]), false);
        }
    }

    /// @custom:function removeFromBlacklist
    /// @notice Should be reverted if caller is not the owner
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

    /// @custom:function configureSaleTimeframe
    /// @notice Expected result:
    ///         - saleStartTime and saleEndTime set to passed values
    function testFuzz_ConfigureSaleTimeframe(uint256 _saleStartTime, uint256 _saleEndTime) public {
        vm.expectEmit(true, true, true, true);
        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);

        presaleContract.configureSaleTimeframe(_saleStartTime, _saleEndTime);

        assertEq(presaleContract.saleStartTime(), _saleStartTime);
        assertEq(presaleContract.saleEndTime(), _saleEndTime);
    }

    /// @notice Should be reverted if caller is not the owner
    function testFuzz_ConfigureSaleTimeframe_RevertOn_NonOwnerCall(
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        address _nonOwner
    ) public {
        vm.assume(_nonOwner != address(presaleContract.owner()));
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.configureSaleTimeframe(_saleStartTime, _saleEndTime);
    }

    /// @notice Should be reverted if caller is not the owner
    function testFuzz_ConfigureClaim_RevertOn_NonOwnerCall(
        uint256 _totalTokensSold,
        uint256 _claimStartTime,
        address _nonOwner
    ) public {
        vm.assume(type(uint256).max / 1e18 > _totalTokensSold);
        vm.assume(_nonOwner != presaleContract.owner());
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        deal(address(tokenContract), address(presaleContract), _totalTokensSold * 1e18);
        assertEq(tokenContract.balanceOf(address(presaleContract)), _totalTokensSold * 1e18);

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_nonOwner);
        presaleContract.configureClaim(_claimStartTime);
    }

    /// @custom:function getCurrentPrice
    /// @notice Expected result:
    ///         - returned price at the current stage
    function test_GetCurrentPrice() public {
        for (uint8 i = 0; i <= presaleContract.MAX_STAGE_INDEX(); i += 1) {
            presaleContract.workaround_setCurrentStage(i);
            assertEq(presaleContract.currentStage(), i);
            assertEq(presaleContract.getCurrentPrice(), pricePerStage[i]);
        }
    }

    /// @custom:function getSoldOnCurrentStage
    /// @notice Expected result:
    ///         - returned amount of tokens sold on a current stage
    function testFuzz_GetSoldOnCurrentStage(uint256 _totalTokensSold) public {
        vm.assume(_totalTokensSold <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        uint8 currentStage = presaleContract.exposed_getStageByTotalSoldAmount();
        presaleContract.workaround_setCurrentStage(currentStage);

        uint256 soldOnCurrentStage = _totalTokensSold - (currentStage == 0 ? 0 : limitPerStage[currentStage - 1]);
        assertEq(soldOnCurrentStage, presaleContract.getSoldOnCurrentStage());
    }

    /// @custom:function totalSoldPrice
    /// @notice Expected result:
    ///         - returned price of all sold tokens in BUSD
    function testFuzz_TotalSoldPrice(uint256 _totalTokensSold) public {
        vm.assume(_totalTokensSold <= limitPerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);
        uint8 currentStage = presaleContract.exposed_getStageByTotalSoldAmount();
        presaleContract.workaround_setCurrentStage(currentStage);

        uint256 sum = 0;

        for (uint256 i = 0; i < currentStage; i += 1) {
            sum += uint256(pricePerStage[i]) * (limitPerStage[i] - (i == 0 ? 0 : limitPerStage[i - 1]));
        }
        sum +=
            pricePerStage[currentStage] *
            (_totalTokensSold - (currentStage == 0 ? 0 : limitPerStage[currentStage - 1]));

        assertEq(presaleContract.totalSoldPrice(), sum);
    }

    /// @custom:function sendValue
    /// @notice Expected result:
    ///         - passed amounts of tokens sent to passed address
    function testFuzz_SendValue(address payable _user, uint256 _amount) public {
        vm.assume(_user.code.length == 0);
        vm.assume(_user >= address(10));
        uint256 balanceBefore = address(_user).balance;
        deal(address(presaleContract), _amount);

        presaleContract.exposed_sendValue(_user, _amount);
        assertEq(address(_user).balance, balanceBefore + _amount);
    }

    /// @custom:function getStageByTotalSoldAmount
    /// @notice Expected result:
    ///         - returned stage that should be if totalTokensSold equal to passed value
    function testFuzz_GetStageByTotalSoldAmount(uint256 _totalTokensSold) public {
        vm.assume(_totalTokensSold <= pricePerStage[presaleContract.MAX_STAGE_INDEX()]);
        presaleContract.workaround_setTotalTokensSold(_totalTokensSold);

        uint8 stageIndex = presaleContract.MAX_STAGE_INDEX();
        while (stageIndex > 0) {
            if (limitPerStage[stageIndex - 1] <= _totalTokensSold) break;
            stageIndex -= 1;
        }

        assertEq(presaleContract.exposed_getStageByTotalSoldAmount(), stageIndex);
    }
}

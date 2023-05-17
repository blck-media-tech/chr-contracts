// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/CHRToken.sol";

/// @title Contract for exposing some internal funcitons and creating workarounds
contract CHRTokenHarness is CHRToken {
    constructor(uint256 _initialSupply) CHRToken(_initialSupply) {}

    function exposed_mint(address _user, uint256 _amount) public {
        _mint(_user, _amount);
    }
}

/// @title Test for Chancer token contract functions
contract CHRTokenTest is Test {
    CHRTokenHarness tokenContract;

    uint256 initialSupply = 250_000_000;
    uint256 cap = 500_000_000;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Expected state - contract deployed, preasle started, claim not started
    function setUp() public virtual {
        tokenContract = new CHRTokenHarness(initialSupply);
    }

    /// @notice Ensure that test initial state was set up correctly
    function test_SetUpState() public {
        assertEq(tokenContract.totalSupply(), initialSupply * 1e18);
    }

    /// @custom:function transfer
    /// @notice Expected result:
    ///         - passed amount of tokens should be transferred to passed address
    ///         - Transfer event emitted
    function testFuzz_Transfer(uint256 _amount, address _transferSource, address _transferTarget) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_amount <= cap);

        tokenContract.exposed_mint(_transferSource, _amount);

        uint256 balanceTarget = tokenContract.balanceOf(_transferTarget);
        uint256 balanceSource = tokenContract.balanceOf(_transferSource);

        vm.expectEmit(true, true, true, true);
        emit Transfer(_transferSource, _transferTarget, _amount);

        vm.prank(_transferSource);
        tokenContract.transfer(_transferTarget, _amount);

        assertEq(
            tokenContract.balanceOf(_transferSource),
            balanceSource - _amount,
            "Source balance does not meet expectations"
        );
        assertEq(
            tokenContract.balanceOf(_transferTarget),
            balanceTarget + _amount,
            "Target balance does not meet expectations"
        );
    }

    /// @custom:function transfer
    /// @notice Should be reverted if caller's balance is not enough to transfer
    function testFuzz_Transfer_RevertOn_NotEnoughBalance(
        uint256 _amount,
        address _transferSource,
        address _transferTarget
    ) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_amount > tokenContract.totalSupply());

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.prank(_transferSource);
        tokenContract.transfer(_transferTarget, _amount);
    }

    /// @custom:function transfer
    /// @notice Should be reverted if caller is zero address
    function testFuzz_Transfer_RevertOn_TransferFromZeroAddress(uint256 _amount, address _transferTarget) public {
        vm.assume(_transferTarget != address(0));
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: transfer from the zero address");

        vm.prank(address(0));
        tokenContract.transfer(_transferTarget, _amount);
    }

    /// @custom:function transfer
    /// @notice Should be reverted if trying to transfer to zero address
    function testFuzz_Transfer_RevertOn_TransferToZeroAddress(uint256 _amount, address _transferSource) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: transfer to the zero address");

        vm.prank(_transferSource);
        tokenContract.transfer(address(0), _amount);
    }

    /// @custom:function transferFrom
    /// @notice Expected result:
    ///         - passed amount of tokens should be transferred from one passed address to another
    ///         - Transfer event emitted
    function testFuzz_TransferFrom(
        uint256 _amount,
        address _transferSource,
        address _transferTarget,
        address _transferExecutor
    ) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferExecutor != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_transferSource != _transferExecutor);
        vm.assume(_transferTarget != _transferExecutor);
        vm.assume(_amount <= cap);

        tokenContract.exposed_mint(_transferSource, _amount);

        vm.prank(_transferSource);
        tokenContract.increaseAllowance(_transferExecutor, _amount);

        uint256 balanceTarget = tokenContract.balanceOf(_transferTarget);
        uint256 balanceSource = tokenContract.balanceOf(_transferSource);
        uint256 balanceExecutor = tokenContract.balanceOf(_transferExecutor);

        vm.prank(_transferExecutor);
        tokenContract.transferFrom(_transferSource, _transferTarget, _amount);

        assertEq(
            tokenContract.balanceOf(_transferSource),
            balanceSource - _amount,
            "Source balance does not meet expectations"
        );
        assertEq(
            tokenContract.balanceOf(_transferTarget),
            balanceTarget + _amount,
            "Target balance does not meet expectations"
        );
        assertEq(tokenContract.balanceOf(_transferExecutor), balanceExecutor, "Executors balance was changed");
    }

    /// @custom:function transferFrom
    /// @notice Should be reverted if caller' don't have enough allowance
    function testFuzz_TransferFrom_RevertOn_NotEnoughAllowance(
        uint256 _amount,
        address _transferSource,
        address _transferTarget,
        address _transferExecutor
    ) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferExecutor != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_transferSource != _transferExecutor);
        vm.assume(_transferTarget != _transferExecutor);
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        tokenContract.exposed_mint(_transferSource, _amount);

        vm.expectRevert("ERC20: insufficient allowance");

        vm.prank(_transferExecutor);
        tokenContract.transferFrom(_transferSource, _transferTarget, _amount);
    }

    /// @custom:function transferFrom
    /// @notice Should be reverted if source address balance is not enough to transfer
    function testFuzz_TransferFrom_RevertOn_NotEnoughBalance(
        uint256 _amount,
        address _transferSource,
        address _transferTarget,
        address _transferExecutor
    ) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferExecutor != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_transferSource != _transferExecutor);
        vm.assume(_transferTarget != _transferExecutor);
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: insufficient allowance");

        vm.prank(_transferExecutor);
        tokenContract.transferFrom(_transferSource, _transferTarget, _amount);
    }

    /// @custom:function transferFrom
    /// @notice Should be reverted if trying to transfer to zero address
    function testFuzz_TransferFrom_RevertOn_TransferToZeroAddress(
        uint256 _amount,
        address _transferSource,
        address _transferExecutor
    ) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferExecutor != address(0));
        vm.assume(_transferSource != _transferExecutor);
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        tokenContract.exposed_mint(_transferSource, _amount);

        vm.prank(_transferSource);
        tokenContract.increaseAllowance(_transferExecutor, _amount);

        vm.expectRevert("ERC20: transfer to the zero address");

        vm.prank(_transferExecutor);
        tokenContract.transferFrom(_transferSource, address(0), _amount);
    }

    /// @custom:function approve
    /// @notice Expected result:
    ///         - allowance of passed address set to passed amount of tokens
    ///         - Approval event emitted
    function testFuzz_Approve(uint256 _amount, address _allowanceSource, address _allowanceTarget) public {
        vm.assume(_allowanceSource != address(0));
        vm.assume(_allowanceTarget != address(0));
        vm.assume(_allowanceSource != _allowanceTarget);

        vm.expectEmit(true, true, true, true);
        emit Approval(_allowanceSource, _allowanceTarget, _amount);

        vm.prank(_allowanceSource);
        tokenContract.approve(_allowanceTarget, _amount);

        assertEq(
            tokenContract.allowance(_allowanceSource, _allowanceTarget),
            _amount,
            "Allowance does not meet expectations"
        );
    }

    /// @custom:function approve
    /// @notice Should revert if caller is zero address
    function testFuzz_Approve_RevertOn_ApproveFromZeroAddress(uint256 _amount, address _allowanceTarget) public {
        vm.assume(_allowanceTarget != address(0));

        vm.expectRevert("ERC20: approve from the zero address");

        vm.prank(address(0));
        tokenContract.approve(_allowanceTarget, _amount);
    }

    /// @custom:function approve
    /// @notice Should revert if trying to approve to zero address
    function testFuzz_Approve_RevertOn_ApproveToZeroAddress(uint256 _amount, address _allowanceSource) public {
        vm.assume(_allowanceSource != address(0));

        vm.expectRevert("ERC20: approve to the zero address");

        vm.prank(_allowanceSource);
        tokenContract.approve(address(0), _amount);
    }

    /// @custom:function increaseAllowance
    /// @notice Expected result:
    ///         - allowance of passed address increased by passed amount of tokens
    ///         - Approval event emitted
    function testFuzz_IncreaseAllowance(
        uint256 _startingAmount,
        uint256 _amount,
        address _allowanceSource,
        address _allowanceTarget
    ) public {
        vm.assume(_allowanceSource != address(0));
        vm.assume(_allowanceTarget != address(0));
        vm.assume(_allowanceSource != _allowanceTarget);
        vm.assume(type(uint256).max - _startingAmount > _amount);

        vm.prank(_allowanceSource);
        tokenContract.approve(_allowanceTarget, _startingAmount);

        uint256 sourceToTargetAllowance = tokenContract.allowance(_allowanceSource, _allowanceTarget);

        vm.expectEmit(true, true, true, true);
        emit Approval(_allowanceSource, _allowanceTarget, sourceToTargetAllowance + _amount);

        vm.prank(_allowanceSource);
        tokenContract.increaseAllowance(_allowanceTarget, _amount);

        assertEq(
            tokenContract.allowance(_allowanceSource, _allowanceTarget),
            sourceToTargetAllowance + _amount,
            "Allowance does not meet expectations"
        );
    }

    /// @custom:function increaseAllowance
    /// @notice Should revert if caller is zero address
    function testFuzz_IncreaseAllowance_RevertOn_ApproveFromZeroAddress(
        uint256 _amount,
        address _allowanceTarget
    ) public {
        vm.assume(_allowanceTarget != address(0));

        vm.expectRevert("ERC20: approve from the zero address");

        vm.prank(address(0));
        tokenContract.increaseAllowance(_allowanceTarget, _amount);
    }

    /// @custom:function increaseAllowance
    /// @notice Should revert if trying to approve to zero address
    function testFuzz_IncreaseAllowance_RevertOn_ApproveToZeroAddress(
        uint256 _amount,
        address _allowanceSource
    ) public {
        vm.assume(_allowanceSource != address(0));

        vm.expectRevert("ERC20: approve to the zero address");

        vm.prank(_allowanceSource);
        tokenContract.increaseAllowance(address(0), _amount);
    }

    /// @custom:function decreaseAllowance
    /// @notice Expected result:
    ///         - allowance of passed address decreased by passed amount of tokens
    ///         - Approval event emitted
    function testFuzz_DecreaseAllowance(
        uint256 _startingAmount,
        uint256 _amount,
        address _allowanceSource,
        address _allowanceTarget
    ) public {
        vm.assume(_allowanceSource != address(0));
        vm.assume(_allowanceTarget != address(0));
        vm.assume(_allowanceSource != _allowanceTarget);
        vm.assume(_startingAmount > _amount);

        vm.prank(_allowanceSource);
        tokenContract.approve(_allowanceTarget, _startingAmount);

        uint256 sourceToTargetAllowance = tokenContract.allowance(_allowanceSource, _allowanceTarget);

        vm.expectEmit(true, true, true, true);
        emit Approval(_allowanceSource, _allowanceTarget, sourceToTargetAllowance - _amount);

        vm.prank(_allowanceSource);
        tokenContract.decreaseAllowance(_allowanceTarget, _amount);

        assertEq(
            tokenContract.allowance(_allowanceSource, _allowanceTarget),
            sourceToTargetAllowance - _amount,
            "Allowance does not meet expectations"
        );
    }

    /// @custom:function increaseAllowance
    /// @notice Should revert if current allowance is less than amount to decrease
    function testFuzz_DecreaseAllowance_RevertOn_DecreasingBelowZero(
        uint256 _startingAmount,
        uint256 _amount,
        address _allowanceSource,
        address _allowanceTarget
    ) public {
        vm.assume(_allowanceSource != address(0));
        vm.assume(_allowanceTarget != address(0));
        vm.assume(_allowanceSource != _allowanceTarget);
        vm.assume(_amount > _startingAmount);

        vm.prank(_allowanceSource);
        tokenContract.approve(_allowanceTarget, _startingAmount);

        vm.expectRevert("ERC20: decreased allowance below zero");

        vm.prank(_allowanceSource);
        tokenContract.decreaseAllowance(_allowanceTarget, _amount);
    }

    /// @custom:function burn
    /// @notice Expected result:
    ///         - passed amount of tokens should be burned from passed address
    function testFuzz_Burn(address _user, uint256 _amount, uint256 _initialBalance) public {
        vm.assume(_amount > 0);
        vm.assume(_user != address(0));
        vm.assume(_initialBalance < type(uint256).max - tokenContract.totalSupply());
        vm.assume(_amount < _initialBalance);

        deal(address(tokenContract), _user, _initialBalance, true);

        uint256 balanceBefore = tokenContract.balanceOf(_user);
        uint256 totalSupplyBefore = tokenContract.totalSupply();

        vm.prank(_user);
        tokenContract.burn(_amount);

        assertEq(tokenContract.balanceOf(_user), balanceBefore - _amount);
        assertEq(tokenContract.totalSupply(), totalSupplyBefore - _amount);
    }

    /// @custom:function burn
    /// @notice Should be reverted if trying to burn from zero address
    function testFuzz_Burn_RevertOn_BurnFromZeroAddress(uint256 _amount, uint256 _initialBalance) public {
        vm.assume(_amount > 0);
        vm.assume(_initialBalance < type(uint256).max - tokenContract.totalSupply());
        vm.assume(_amount < _initialBalance);

        vm.expectRevert("ERC20: burn from the zero address");

        vm.prank(address(0));
        tokenContract.burn(_amount);
    }

    /// @custom:function burn
    /// @notice Should be reverted if trying to burn more than address balance
    function testFuzz_Burn_RevertOn_BurnExceedsBalance(address _user, uint256 _amount, uint256 _initialBalance) public {
        vm.assume(_user != address(0));
        vm.assume(_initialBalance < type(uint256).max - tokenContract.totalSupply());
        vm.assume(_amount > _initialBalance);

        deal(address(tokenContract), _user, _initialBalance, true);

        vm.expectRevert("ERC20: burn amount exceeds balance");

        vm.prank(_user);
        tokenContract.burn(_amount);
    }
}

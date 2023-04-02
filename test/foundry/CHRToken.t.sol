// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/CHRToken.sol";

contract CHRTokenHarness is CHRToken {
    constructor (
        uint256 _initialSupply
    ) CHRToken(_initialSupply){}

    function exposed_mint(address _user, uint256 _amount) public {
        _mint(_user, _amount);
    }
}

contract CHRTokenTest is Test {
    CHRTokenHarness tokenContract;

    uint256 initialSupply = 250_000_000;
    uint256 cap = 500_000_000;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        tokenContract = new CHRTokenHarness(initialSupply);
    }

    function test_SetUpState() public {
        assertEq(tokenContract.totalSupply(), initialSupply * 1e18);
    }

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

        assertEq(tokenContract.balanceOf(_transferSource), balanceSource - _amount, "Source balance does not meet expectations");
        assertEq(tokenContract.balanceOf(_transferTarget), balanceTarget + _amount, "Target balance does not meet expectations");
    }

    function testFuzz_Transfer_RevertWhen_NotEnoughBalance(uint256 _amount, address _transferSource, address _transferTarget) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_amount > tokenContract.totalSupply());

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.prank(_transferSource);
        tokenContract.transfer(_transferTarget, _amount);
    }

    function testFuzz_Transfer_RevertWhen_TransferFromZeroAddress(uint256 _amount, address _transferTarget) public {
        vm.assume(_transferTarget != address(0));
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: transfer from the zero address");

        vm.prank(address(0));
        tokenContract.transfer(_transferTarget, _amount);
    }

    function testFuzz_Transfer_RevertWhen_TransferToZeroAddress(uint256 _amount, address _transferSource) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: transfer to the zero address");

        vm.prank(_transferSource);
        tokenContract.transfer(address(0), _amount);
    }

    function testFuzz_TransferFrom(uint256 _amount, address _transferSource, address _transferTarget, address _transferExecutor) public {
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

        assertEq(tokenContract.balanceOf(_transferSource), balanceSource - _amount, "Source balance does not meet expectations");
        assertEq(tokenContract.balanceOf(_transferTarget), balanceTarget + _amount, "Target balance does not meet expectations");
        assertEq(tokenContract.balanceOf(_transferExecutor), balanceExecutor, "Executors balance was changed");
    }

    function testFuzz_TransferFrom_RevertWhen_NotEnoughAllowance(uint256 _amount, address _transferSource, address _transferTarget, address _transferExecutor) public {
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

    function testFuzz_TransferFrom_RevertWhen_NotEnoughBalance(uint256 _amount, address _transferSource, address _transferTarget, address _transferExecutor) public {
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

    function testFuzz_TransferFrom_RevertWhen_TransferToZeroAddress(uint256 _amount, address _transferSource, address _transferExecutor) public {
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

    function testFuzz_Approve(uint256 _amount, address _allowanceSource, address _allowanceTarget) public {
        vm.assume(_allowanceSource != address(0));
        vm.assume(_allowanceTarget != address(0));
        vm.assume(_allowanceSource != _allowanceTarget);

        vm.expectEmit(true, true, true, true);
        emit Approval(_allowanceSource, _allowanceTarget, _amount);

        vm.prank(_allowanceSource);
        tokenContract.approve(_allowanceTarget, _amount);

        assertEq(tokenContract.allowance(_allowanceSource, _allowanceTarget), _amount, "Allowance does not meet expectations");
    }

    function testFuzz_Approve_RevertWhen_ApproveFromZeroAddress(uint256 _amount, address _allowanceTarget) public {
        vm.assume(_allowanceTarget != address(0));

        vm.expectRevert("ERC20: approve from the zero address");

        vm.prank(address(0));
        tokenContract.approve(_allowanceTarget, _amount);
    }

    function testFuzz_Approve_RevertWhen_ApproveToZeroAddress(uint256 _amount, address _allowanceSource) public {
        vm.assume(_allowanceSource != address(0));

        vm.expectRevert("ERC20: approve to the zero address");

        vm.prank(_allowanceSource);
        tokenContract.approve(address(0), _amount);
    }

    function testFuzz_IncreaseAllowance(uint256 _startingAmount, uint256 _amount, address _allowanceSource, address _allowanceTarget) public {
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

        assertEq(tokenContract.allowance(_allowanceSource, _allowanceTarget), sourceToTargetAllowance + _amount, "Allowance does not meet expectations");
    }

    function testFuzz_IncreaseAllowance_RevertWhen_ApproveFromZeroAddress(uint256 _amount, address _allowanceTarget) public {
        vm.assume(_allowanceTarget != address(0));

        vm.expectRevert("ERC20: approve from the zero address");

        vm.prank(address(0));
        tokenContract.increaseAllowance(_allowanceTarget, _amount);
    }

    function testFuzz_IncreaseAllowance_RevertWhen_ApproveToZeroAddress(uint256 _amount, address _allowanceSource) public {
        vm.assume(_allowanceSource != address(0));

        vm.expectRevert("ERC20: approve to the zero address");

        vm.prank(_allowanceSource);
        tokenContract.increaseAllowance(address(0), _amount);
    }

    function testFuzz_DecreaseAllowance(uint256 _startingAmount, uint256 _amount, address _allowanceSource, address _allowanceTarget) public {
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

        assertEq(tokenContract.allowance(_allowanceSource, _allowanceTarget), sourceToTargetAllowance - _amount, "Allowance does not meet expectations");
    }

    function testFuzz_DecreaseAllowance_RevertWhen_DecreasingBelowZero(uint256 _startingAmount, uint256 _amount, address _allowanceSource, address _allowanceTarget) public {
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
}

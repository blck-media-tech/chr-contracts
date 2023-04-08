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

    function setUp() public virtual {
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

    function testFuzz_Transfer_RevertOn_NotEnoughBalance(uint256 _amount, address _transferSource, address _transferTarget) public {
        vm.assume(_transferSource != address(0));
        vm.assume(_transferTarget != address(0));
        vm.assume(_transferSource != _transferTarget);
        vm.assume(_amount > tokenContract.totalSupply());

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.prank(_transferSource);
        tokenContract.transfer(_transferTarget, _amount);
    }

    function testFuzz_Transfer_RevertOn_TransferFromZeroAddress(uint256 _amount, address _transferTarget) public {
        vm.assume(_transferTarget != address(0));
        vm.assume(_amount <= cap);
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: transfer from the zero address");

        vm.prank(address(0));
        tokenContract.transfer(_transferTarget, _amount);
    }

    function testFuzz_Transfer_RevertOn_TransferToZeroAddress(uint256 _amount, address _transferSource) public {
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

    function testFuzz_TransferFrom_RevertOn_NotEnoughAllowance(uint256 _amount, address _transferSource, address _transferTarget, address _transferExecutor) public {
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

    function testFuzz_TransferFrom_RevertOn_NotEnoughBalance(uint256 _amount, address _transferSource, address _transferTarget, address _transferExecutor) public {
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

    function testFuzz_TransferFrom_RevertOn_TransferToZeroAddress(uint256 _amount, address _transferSource, address _transferExecutor) public {
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

    function testFuzz_Approve_RevertOn_ApproveFromZeroAddress(uint256 _amount, address _allowanceTarget) public {
        vm.assume(_allowanceTarget != address(0));

        vm.expectRevert("ERC20: approve from the zero address");

        vm.prank(address(0));
        tokenContract.approve(_allowanceTarget, _amount);
    }

    function testFuzz_Approve_RevertOn_ApproveToZeroAddress(uint256 _amount, address _allowanceSource) public {
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

    function testFuzz_IncreaseAllowance_RevertOn_ApproveFromZeroAddress(uint256 _amount, address _allowanceTarget) public {
        vm.assume(_allowanceTarget != address(0));

        vm.expectRevert("ERC20: approve from the zero address");

        vm.prank(address(0));
        tokenContract.increaseAllowance(_allowanceTarget, _amount);
    }

    function testFuzz_IncreaseAllowance_RevertOn_ApproveToZeroAddress(uint256 _amount, address _allowanceSource) public {
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

    function testFuzz_DecreaseAllowance_RevertOn_DecreasingBelowZero(uint256 _startingAmount, uint256 _amount, address _allowanceSource, address _allowanceTarget) public {
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

    function testFuzz_Mint(address _user, uint248 _amount, uint248 _initialBalance) public {
        vm.assume(_amount > 0);

        deal(address(tokenContract), _user, _initialBalance, true);

        uint256 balanceBefore = tokenContract.balanceOf(_user);
        uint256 totalSupplyBefore = tokenContract.totalSupply();

        vm.prank(tokenContract.owner());
        tokenContract.mint(_user, _amount);

        assertEq(tokenContract.balanceOf(_user), balanceBefore + _amount);
        assertEq(tokenContract.totalSupply(), totalSupplyBefore + _amount);
    }

    function testFuzz_Mint_RevertOn_NonOwnerCall(address _user, uint248 _amount, uint248 _initialBalance) public {
        vm.assume(_amount > 0);
        vm.assume(_user != address(0));
        vm.assume(_user != tokenContract.owner());

        deal(address(tokenContract), _user, _initialBalance, true);

        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_user);
        tokenContract.mint(_user, _amount);
    }

    function testFuzz_Mint_RevertOn_MintToZeroAddress(uint256 _amount) public {
        vm.assume(_amount > 0);

        vm.expectRevert("ERC20: mint to the zero address");

        tokenContract.mint(address(0), _amount);
    }

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

    function testFuzz_Burn_RevertOn_BurnFromZeroAddress(uint256 _amount, uint256 _initialBalance) public {
        vm.assume(_amount > 0);
        vm.assume(_initialBalance < type(uint256).max - tokenContract.totalSupply());
        vm.assume(_amount < _initialBalance);

        vm.expectRevert("ERC20: burn from the zero address");

        vm.prank(address(0));
        tokenContract.burn(_amount);
    }

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

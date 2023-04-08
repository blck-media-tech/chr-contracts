// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/test/CHRToken.testnet.sol";
import "../contracts/CHRToken.t.sol";

contract CHRTokenTestnetHarness is CHRTokenTestnet {
    constructor (
        uint256 _initialSupply
    ) CHRTokenTestnet(_initialSupply){}

    function exposed_mint(address _user, uint256 _amount) public {
        _mint(_user, _amount);
    }
}

contract CHRTokenTestnetTest is CHRTokenTest {
    CHRTokenTestnetHarness tokenContractTestnet;

    function setUp() public override {
        tokenContractTestnet = new CHRTokenTestnetHarness(initialSupply);
        tokenContract = CHRTokenHarness(address(tokenContractTestnet));
    }

    function testFuzz_T_Mint(address _user, uint248 _amount, uint248 _initialBalance) public {
        vm.assume(_amount > 0);
        vm.assume(_user != address(0));

        deal(address(tokenContractTestnet), _user, _initialBalance, true);

        uint256 balanceBefore = tokenContractTestnet.balanceOf(_user);
        uint256 totalSupplyBefore = tokenContractTestnet.totalSupply();

        vm.prank(_user);
        tokenContractTestnet.t_mint(_user, _amount);

        assertEq(tokenContractTestnet.balanceOf(_user), balanceBefore + _amount);
        assertEq(tokenContractTestnet.totalSupply(), totalSupplyBefore + _amount);
    }

    function testFuzz_T_Burn(address _user, uint256 _amount, uint256 _initialBalance) public {
        vm.assume(_amount > 0);
        vm.assume(_user != address(0));
        vm.assume(_initialBalance < type(uint256).max - tokenContractTestnet.totalSupply());
        vm.assume(_amount < _initialBalance);

        deal(address(tokenContractTestnet), _user, _initialBalance, true);

        uint256 balanceBefore = tokenContractTestnet.balanceOf(_user);
        uint256 totalSupplyBefore = tokenContractTestnet.totalSupply();

        vm.prank(_user);
        tokenContractTestnet.t_burn(_user, _amount);

        assertEq(tokenContractTestnet.balanceOf(_user), balanceBefore - _amount);
        assertEq(tokenContractTestnet.totalSupply(), totalSupplyBefore - _amount);
    }
}

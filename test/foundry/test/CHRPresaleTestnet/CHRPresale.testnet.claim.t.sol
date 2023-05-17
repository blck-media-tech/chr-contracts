// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
            address(mockBUSD),
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );
        presaleContract = CHRPresaleHarness(address(presaleContractTestnet));

        vm.warp(claimStartTime);

        presaleContractTestnet.configureClaim(claimStartTime);
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
}

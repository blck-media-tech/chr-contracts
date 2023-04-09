// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/test/ChainLinkAggregator.mock.sol";

contract ChainLinkAggregatorMockDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ChainLinkAggregatorMock chainLinkAggregatorMockContract = new ChainLinkAggregatorMock();

        vm.stopBroadcast();
    }
}

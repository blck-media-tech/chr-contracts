// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/test/CHRToken.testnet.sol";

contract CHRTokenTestnetDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CHRTokenTestnet tokenContract = new CHRTokenTestnet(250_000_000 * 1e18);

        vm.stopBroadcast();
    }
}

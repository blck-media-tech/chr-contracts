// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract USDTMockDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address USDTMockContract = deployCode("USDT.mock.sol:USDTMock", abi.encode(0, "USDT mock", "USDT", 6));

        vm.stopBroadcast();
    }
}

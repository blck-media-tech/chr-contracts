// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract BUSDMockDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address BUSDMockContract = deployCode("BUSD.mock.sol:BUSDMock", abi.encode());

        vm.stopBroadcast();
    }
}

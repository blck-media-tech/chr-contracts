// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/test/CHRPresale.testnet.sol";

contract CHRPresaleTestnetDeployScript is Script {
    address tokenContract = 0xe94aEBBf933EC1E50Fa6efc5DcC30A3A52614a4C;
    address mockUSDT = 0x6b423B7Dd9c36AeDcF16525e6Eb827c7a3a4FA11;
    address mockAggregator = 0x1E5CAdBDA5494C8cf1f348e0A64AEb8A66604813;

    uint256 saleStartTime = 1680739200;
    uint256 saleEndTime = 1688162400;

    uint256[4] limitPerStage = [1_000_000_000, 2_000_000_000, 3_000_000_000, 4_000_000_000];
    uint256[4] pricePerStage = [100_000, 200_000, 400_000, 800_000];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CHRPresaleTestnet presaleContract = new CHRPresaleTestnet(
            tokenContract,
            mockAggregator,
            mockUSDT,
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        vm.stopBroadcast();
    }
}

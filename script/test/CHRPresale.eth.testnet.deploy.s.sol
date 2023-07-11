// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/test/CHRPresale.eth.testnet.sol";

contract CHRPresaleETHTestnetDeployScript is Script {
    address tokenContract = 0xe94aEBBf933EC1E50Fa6efc5DcC30A3A52614a4C;
    address mockUSDT = 0x6b423B7Dd9c36AeDcF16525e6Eb827c7a3a4FA11;
    address mockAggregator = 0x5A72C337A1f3E32DB7439C1267F8f4D8c6aBF460;

    uint256 saleStartTime = 1680739200;
    uint256 saleEndTime = 1688162400;

    uint32[12] limitPerStage = [
        100_000_000,
        190_909_091, // +  90_909_091
        274_242_424, // +  83_333_333
        351_165_501, // +  76_923_077
        422_594_072, // +  71_428_571
        489_260_739, // +  66_666_667
        551_760_739, // +  62_500_000
        610_584_268, // +  58_823_529
        666_139_824, // +  55_555_556
        718_771_403, // +  52_631_579
        818_771_403, // + 100_000_000
        961_628_546 // + 142_857_143
    ];
    uint64[12] pricePerStage = [
        10_000,
        11_000,
        12_000,
        13_000,
        14_000,
        15_000,
        16_000,
        17_000,
        18_000,
        19_000,
        20_000,
        21_000
    ];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CHRPresaleETHTestnet presaleContract = new CHRPresaleETHTestnet(
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

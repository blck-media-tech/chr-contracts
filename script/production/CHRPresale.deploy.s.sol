// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/CHRPresale.sol";

contract CHRPresaleDeployScript is Script {
    address tokenContract = 0xcbC7019E3C7f003bc04F3493eBBE75335808C892;
    address mockUSDT = 0x6b423B7Dd9c36AeDcF16525e6Eb827c7a3a4FA11;
    address mockAggregator = 0x1E5CAdBDA5494C8cf1f348e0A64AEb8A66604813;

    uint256 saleStartTime = 1680739200;
    uint256 saleEndTime = 1688162400;

    uint256[12] limitPerStage = [
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
    uint256[12] pricePerStage = [
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

        CHRPresale presaleContract = new CHRPresale(
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/CHRPresale.eth.sol";

contract CHRPresaleDeployScript is Script {
    address tokenContract = address(0);
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address ChainlinkAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    uint256 saleStartTime = 1686654000;
    uint256 saleEndTime = 1697194800;

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

        CHRPresaleETH presaleContract = new CHRPresaleETH(
            tokenContract,
            ChainlinkAggregator,
            USDT,
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        vm.stopBroadcast();
    }
}

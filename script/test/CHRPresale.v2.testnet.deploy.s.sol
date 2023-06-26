
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/test/CHRPresale.v2.testnet.sol";

contract CHRPresaleV2TestnetDeployScript is Script {
    address tokenContract = 0xBdB6016CdFea496aAFD5feD0B680fD9fbc0818b3;
    address mockBUSD = 0x769227dA80e38511cA261874F1542Ce866A2957b;
    address mockAggregator = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    address presaleV1 = 0x3F7b2D56F5B3bb71Ed65cF59d7e802E1Acdc277d;

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
        10_000_000_000_000_000,
        11_000_000_000_000_000,
        12_000_000_000_000_000,
        13_000_000_000_000_000,
        14_000_000_000_000_000,
        15_000_000_000_000_000,
        16_000_000_000_000_000,
        17_000_000_000_000_000,
        18_000_000_000_000_000,
        19_000_000_000_000_000,
        20_000_000_000_000_000,
        21_000_000_000_000_000
    ];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CHRPresaleV2Testnet presaleContract = new CHRPresaleV2Testnet(
            tokenContract,
            mockAggregator,
            mockBUSD,
            presaleV1,
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        vm.stopBroadcast();
    }
}

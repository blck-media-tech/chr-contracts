
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "contracts/CHRPresale.v2.sol";

contract CHRPresaleDeployScript is Script {
    address tokenContract = 0xcbC7019E3C7f003bc04F3493eBBE75335808C892;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address ChainlinkAggregator = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address presaleV1 = address(0);

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

        CHRPresaleV2 presaleContract = new CHRPresaleV2(
            tokenContract,
            ChainlinkAggregator,
            BUSD,
            presaleV1,
            saleStartTime,
            saleEndTime,
            limitPerStage,
            pricePerStage
        );

        vm.stopBroadcast();
    }
}

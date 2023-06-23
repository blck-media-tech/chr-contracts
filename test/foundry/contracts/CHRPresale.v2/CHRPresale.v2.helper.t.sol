// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/CHRPresale.v2.sol";
import "contracts/CHRToken.sol";
import "contracts/test/ChainLinkAggregator.mock.sol";

/// @title Contract for exposing some internal funcitons and creating workarounds
contract CHRPresaleV2Harness is CHRPresaleV2 {
    constructor(
        address _saleToken,
        address _oracle,
        address _busd,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint32[12] memory _limitPerStage,
        uint64[12] memory _pricePerStage
    ) CHRPresaleV2(_saleToken, _oracle, _busd, _saleStartTime, _saleEndTime, _limitPerStage, _pricePerStage) {}

    /// @notice exposing internal function for testing
    function exposed_sendValue(address payable _recipient, uint256 _ethAmount) public {
        _sendValue(_recipient, _ethAmount);
    }

    /// @notice exposing internal function for testing
    function exposed_calculatePriceInBUSDForConditions(
        uint256 _amount,
        uint256 _currentStage,
        uint256 _totalTokensSold
    ) public view returns (uint256) {
        return _calculatePriceInBUSDForConditions(_amount, _currentStage, _totalTokensSold);
    }

    /// @notice exposing internal function for testing
    function exposed_getStageByTotalSoldAmount() public view returns (uint8) {
        return _getStageByTotalSoldAmount();
    }

    /// @notice Workaround for manual setting totalTokensSold value
    /// @dev should be used when test depends only on amount of sold tokens
    function workaround_setTotalTokensSold(uint256 _amount) public {
        totalTokensSold = _amount;
    }

    /// @notice Workaround for manual setting currentStage value
    /// @dev should be used when test depends only on current stage
    /// @dev Note: purchasing tokens will set currentStage back to correct value
    function workaround_setCurrentStage(uint8 _currentStage) public {
        currentStage = _currentStage;
    }
}

/// @title Helper contract with useful stuff for tests
contract CHRPresaleV2Helper is Test {
    CHRPresaleV2Harness presaleContract;
    CHRToken tokenContract;
    ChainLinkAggregatorMock mockAggregator;
    address mockBUSD;
    IERC20 mockBUSDWrapped;

    uint256 totalSupply = 1_000_000_000;

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
    uint256 timeDelay = 1 days;

    constructor() {
        tokenContract = new CHRToken(totalSupply);
        mockAggregator = new ChainLinkAggregatorMock();
        mockBUSD = deployCode("BUSD.mock.sol:BUSDMock", abi.encode());
        mockBUSDWrapped = IERC20(mockBUSD);
    }

    /// @notice Helper for purchasing tokens
    /// @dev should be used if test is not dependent on way of purchasing but on the fact it was and amount of purchased tokens
    function helper_purchaseTokens(address _user, uint256 _amount, address _owner, uint256 _referrerId) public {
        uint256 startTime = block.timestamp;
        vm.warp(presaleContract.saleStartTime());
        (uint256 priceInBNB, uint256 priceInBUSD) = presaleContract.getPrice(_amount);

        vm.prank(presaleContract.owner());
        presaleContract.transferOwnership(_owner);

        vm.deal(_user, priceInBNB);
        deal(address(tokenContract), address(presaleContract), _amount * 1e18, true);

        vm.prank(_user);
        presaleContract.buyWithBnb{ value: priceInBNB }(_amount, _referrerId);
        vm.warp(startTime);
    }
}

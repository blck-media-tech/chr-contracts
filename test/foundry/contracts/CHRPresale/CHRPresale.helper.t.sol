// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/CHRPresale.sol";
import "contracts/CHRToken.sol";
import "contracts/test/ChainLinkAggregator.mock.sol";

/// @title Contract for exposing some internal funcitons and creating workarounds
contract CHRPresaleHarness is CHRPresale {
    constructor(
        address _saleToken,
        address _oracle,
        address _usdt,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256[4] memory _limitPerStage,
        uint256[4] memory _pricePerStage
    ) CHRPresale(_saleToken, _oracle, _usdt, _saleStartTime, _saleEndTime, _limitPerStage, _pricePerStage) {}

    /// @notice exposing internal function for testing
    function exposed_sendValue(address payable _recipient, uint256 _ethAmount) public {
        _sendValue(_recipient, _ethAmount);
    }

    /// @notice exposing internal function for testing
    function exposed_calculatePriceInUSDTForConditions(
        uint256 _amount,
        uint256 _currentStage,
        uint256 _totalTokensSold
    ) public view returns (uint256) {
        return _calculatePriceInUSDTForConditions(_amount, _currentStage, _totalTokensSold);
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
contract CHRPresaleHelper is Test {
    CHRPresaleHarness presaleContract;
    CHRToken tokenContract;
    ChainLinkAggregatorMock mockAggregator;
    address mockUSDT;
    IERC20 mockUSDTWrapped;

    uint256 totalSupply = 1_000_000;
    uint256[4] limitPerStage = [1_000_000_000, 2_000_000_000, 3_000_000_000, 4_000_000_000];
    uint256[4] pricePerStage = [100_000, 200_000, 400_000, 800_000];
    uint256 timeDelay = 1 days;

    constructor() {
        tokenContract = new CHRToken(totalSupply);
        mockAggregator = new ChainLinkAggregatorMock();
        mockUSDT = deployCode("USDT.mock.sol:USDTMock", abi.encode(0, "USDT mock", "USDT", 6));
        mockUSDTWrapped = IERC20(mockUSDT);
    }

    /// @notice Helper for purchasing tokens
    /// @dev should be used if test is not dependent on way of purchasing but on the fact it was and amount of purchased tokens
    function helper_purchaseTokens(address _user, uint256 _amount, address _owner) public {
        uint256 startTime = block.timestamp;
        vm.warp(presaleContract.saleStartTime());
        (uint256 priceInETH, uint256 priceInUSDT) = presaleContract.getPrice(_amount);

        vm.prank(presaleContract.owner());
        presaleContract.transferOwnership(_owner);

        vm.deal(_user, priceInETH);
        deal(address(tokenContract), address(presaleContract), _amount * 1e18, true);

        vm.prank(_user);
        presaleContract.buyWithEth{ value: priceInETH }(_amount);
        vm.warp(startTime);
    }
}

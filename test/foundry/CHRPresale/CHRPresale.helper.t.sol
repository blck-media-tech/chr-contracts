// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "contracts/CHRPresale.sol";
import "contracts/CHRToken.sol";
import "contracts/test/MockAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function exposed_sendValue(address payable _recipient, uint256 _ethAmount) public {
        _sendValue(_recipient, _ethAmount);
    }

    function exposed_calculatePriceInUSDTForConditions(uint256 _amount, uint256 _currentStage, uint256 _totalTokensSold) public view returns (uint256 cost) {
        cost = _calculatePriceInUSDTForConditions(_amount, _currentStage, _totalTokensSold);
    }

    function exposed_getStageByTotalSoldAmount() public view returns (uint8) {
        return _getStageByTotalSoldAmount();
    }

    function workaround_setTotalTokensSold(uint256 _amount) public {
        totalTokensSold = _amount;
    }

    function workaround_setCurrentStage(uint8 _currentStage) public {
        currentStage = _currentStage;
    }
}

contract CHRPresaleHelper is Test {
    CHRPresaleHarness presaleContract;
    CHRToken tokenContract;
    MockAggregator mockAggregator;
    IERC20 mockUSDT;

    uint256 totalSupply = 1_000_000;
    uint256[4] limitPerStage = [1_000_000_000, 2_000_000_000, 3_000_000_000, 4_000_000_000];
    uint256[4] pricePerStage = [100_000, 200_000, 400_000, 800_000];

    constructor() {
        tokenContract = new CHRToken(totalSupply);
        mockAggregator = new MockAggregator();
        address mockUSDTAddress = deployCode("USDT.mock.sol:USDTMock", abi.encode(0, "USDT mock", "USDT", 6));
        mockUSDT = IERC20(mockUSDTAddress);
    }
}
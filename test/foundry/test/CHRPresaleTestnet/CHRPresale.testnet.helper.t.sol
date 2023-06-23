// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "contracts/CHRToken.sol";
import "contracts/test/ChainLinkAggregator.mock.sol";
import "contracts/test/CHRPresale.testnet.sol";
import "../../contracts/CHRPresale/CHRPresale.helper.t.sol";

contract CHRPresaleTestnetHarness is CHRPresaleTestnet {
    constructor(
        address _saleToken,
        address _oracle,
        address _busd,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint32[12] memory _limitPerStage,
        uint64[12] memory _pricePerStage
    ) CHRPresaleTestnet(_saleToken, _oracle, _busd, _saleStartTime, _saleEndTime, _limitPerStage, _pricePerStage) {}

    function exposed_sendValue(address payable _recipient, uint256 _ethAmount) public {
        _sendValue(_recipient, _ethAmount);
    }

    function exposed_calculatePriceInBUSDForConditions(
        uint256 _amount,
        uint256 _currentStage,
        uint256 _totalTokensSold
    ) public view returns (uint256 cost) {
        cost = _calculatePriceInBUSDForConditions(_amount, _currentStage, _totalTokensSold);
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

    function workaround_setPurchasedTokens(address _user, uint256 _amount) public {
        purchasedTokens[_user] = _amount;
    }

    function workaround_setUserClaimed(address _user) public {
        hasClaimed[_user] = true;
    }
}

contract CHRPresaleTestnetHelper is Test, CHRPresaleHelper {
    CHRPresaleTestnetHarness presaleContractTestnet;

    constructor() {
        tokenContract = new CHRToken(totalSupply);
        mockAggregator = new ChainLinkAggregatorMock();
        mockBUSD = deployCode("BUSD.mock.sol:BUSDMock", abi.encode());
        mockBUSDWrapped = IERC20(mockBUSD);
    }

    function helper_prepareToClaim(address _user, uint256 _amount) public {
        presaleContractTestnet.workaround_setPurchasedTokens(_user, _amount);
        deal(address(tokenContract), address(presaleContractTestnet), _amount, true);
    }

    function helper_simulateClaim(address _user) public {
        presaleContractTestnet.workaround_setUserClaimed(_user);
    }
}

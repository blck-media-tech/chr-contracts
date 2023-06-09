// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/security/Pausable.sol";
import "./openzeppelin/security/ReentrancyGuard.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/IPresale.sol";

/// @title Presale contract for Chancer token
contract CHRPresale is IPresale, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Address of token contract
    address public immutable saleToken;

    /// @notice Address of BUSD token
    IERC20 public immutable busdToken;

    /// @notice Address of chainlink BNB/USD price feed
    IChainlinkPriceFeed public immutable oracle;

    /// @notice Last stage index
    uint8 public constant MAX_STAGE_INDEX = 11;

    /// @notice Total amount of purchased tokens
    uint256 public totalTokensSold;

    /// @notice Timestamp when purchased tokens claim starts
    uint256 public claimStartTime;

    /// @notice Timestamp when presale starts
    uint256 public saleStartTime;

    /// @notice Timestamp when presale ends
    uint256 public saleEndTime;

    /// @notice Array representing cap values of totalTokensSold for each presale stage
    uint32[12] public limitPerStage;

    /// @notice Sale prices for each stage
    uint64[12] public pricePerStage;

    /// @notice Index of current stage
    uint8 public currentStage;

    /// @notice Stores the number of tokens purchased by each user that have not yet been claimed
    mapping(address => uint256) public purchasedTokens;

    /// @notice Indicates whbnber the user is blacklisted or not
    mapping(address => bool) public blacklist;

    /// @notice Indicates whbnber the user already claimed or not
    mapping(address => bool) public hasClaimed;

    /// @notice Checks that it is now possible to purchase passed amount tokens
    /// @param amount - the number of tokens to verify the possibility of purchase
    modifier verifyPurchase(uint256 amount) {
        if (block.timestamp < saleStartTime || block.timestamp >= saleEndTime) revert InvalidTimeframe();
        if (amount == 0) revert BuyAtLeastOneToken();
        if (amount + totalTokensSold > limitPerStage[MAX_STAGE_INDEX])
            revert PresaleLimitExceeded(limitPerStage[MAX_STAGE_INDEX] - totalTokensSold);
        _;
    }

    /// @notice Verifies that the sender isn't blacklisted
    modifier notBlacklisted() {
        if (blacklist[_msgSender()]) revert AddressBlacklisted();
        _;
    }

    /// @notice Creates the contract
    /// @param _saleToken      - Address of presailing token
    /// @param _oracle         - Address of Chainlink BNB/USD price feed
    /// @param _busd           - Address of BUSD token
    /// @param _limitPerStage  - Array representing cap values of totalTokensSold for each presale stage
    /// @param _pricePerStage  - Array of prices for each presale stage
    /// @param _saleStartTime  - Sale start time
    /// @param _saleEndTime    - Sale end time
    constructor(
        address _saleToken,
        address _oracle,
        address _busd,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint32[12] memory _limitPerStage,
        uint64[12] memory _pricePerStage
    ) {
        if (_oracle == address(0)) revert ZeroAddress("Aggregator");
        if (_busd == address(0)) revert ZeroAddress("BUSD");
        if (_saleToken == address(0)) revert ZeroAddress("Sale token");

        saleToken = _saleToken;
        oracle = IChainlinkPriceFeed(_oracle);
        busdToken = IERC20(_busd);
        limitPerStage = _limitPerStage;
        pricePerStage = _pricePerStage;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;

        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);
    }

    /// @notice To pause the presale
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice To unpause the presale
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice To add users to blacklist
    /// @param _users - Array of addresses to add in blacklist
    function addToBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while (i < usersAmount) {
            blacklist[_users[i]] = true;
            emit AddedToBlacklist(_users[i], block.timestamp);
            i += 1;
        }
    }

    /// @notice To remove users from blacklist
    /// @param _users - Array of addresses to remove from blacklist
    function removeFromBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while (i < usersAmount) {
            blacklist[_users[i]] = false;
            emit RemovedFromBlacklist(_users[i], block.timestamp);
            i += 1;
        }
    }

    /// @notice To update the sale start and end times
    /// @param _saleStartTime - New sales start time
    /// @param _saleEndTime   - New sales end time
    function configureSaleTimeframe(uint256 _saleStartTime, uint256 _saleEndTime) external onlyOwner {
        if (saleStartTime != _saleStartTime) saleStartTime = _saleStartTime;
        if (saleEndTime != _saleEndTime) saleEndTime = _saleEndTime;
        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);
    }

    /// @notice To set the claim start time
    /// @param _claimStartTime - claim start time
    /// @notice Function also makes sure that presale have enough sale token balance
    /// @dev Function can be executed only after the end of the presale, so totalTokensSold value here is final and will not change
    function configureClaim(uint256 _claimStartTime) external onlyOwner {
        if (block.timestamp < saleEndTime) revert PresaleNotEnded();
        require(IERC20(saleToken).balanceOf(address(this)) >= totalTokensSold * 1e18, "Not enough tokens on contract");
        claimStartTime = _claimStartTime;
        emit ClaimTimeUpdated(_claimStartTime, block.timestamp);
    }

    /// @notice To buy into a presale using BNB with referrer
    /// @param _amount - Amount of tokens to buy
    /// @param _referrerId - id of the referrer
    function buyWithBnb(
        uint256 _amount,
        uint256 _referrerId
    ) public payable notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        (uint256 priceInBNB, uint256 priceInBUSD) = getPrice(_amount);
        if (msg.value < priceInBNB) revert NotEnoughBNB(msg.value, priceInBNB);
        uint256 excess = msg.value - priceInBNB;
        totalTokensSold += _amount;
        purchasedTokens[_msgSender()] += _amount;
        uint8 stageAfterPurchase = _getStageByTotalSoldAmount();
        if (stageAfterPurchase > currentStage) currentStage = stageAfterPurchase;
        _sendValue(payable(owner()), priceInBNB);
        if (excess > 0) _sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), "BNB", _amount, priceInBUSD, priceInBNB, _referrerId, block.timestamp);
    }

    /// @notice To buy into a presale using BUSD with referrer
    /// @param _amount - Amount of tokens to buy
    /// @param _referrerId - id of the referrer
    function buyWithBUSD(
        uint256 _amount,
        uint256 _referrerId
    ) public notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        (uint256 priceInBNB, uint256 priceInBUSD) = getPrice(_amount);
        uint256 allowance = busdToken.allowance(_msgSender(), address(this));
        if (priceInBUSD > allowance) revert NotEnoughAllowance(allowance, priceInBUSD);
        totalTokensSold += _amount;
        purchasedTokens[_msgSender()] += _amount;
        uint8 stageAfterPurchase = _getStageByTotalSoldAmount();
        if (stageAfterPurchase > currentStage) currentStage = stageAfterPurchase;
        busdToken.safeTransferFrom(_msgSender(), owner(), priceInBUSD);
        emit TokensBought(_msgSender(), "BUSD", _amount, priceInBUSD, priceInBNB, _referrerId, block.timestamp);
    }

    /// @notice To claim tokens after claiming starts
    function claim() external whenNotPaused {
        if (block.timestamp < claimStartTime || claimStartTime == 0) revert InvalidTimeframe();
        if (hasClaimed[_msgSender()]) revert AlreadyClaimed();
        uint256 amount = purchasedTokens[_msgSender()] * 1e18;
        if (amount == 0) revert NothingToClaim();
        hasClaimed[_msgSender()] = true;
        IERC20(saleToken).safeTransfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    /// @notice Returns price for current stage
    function getCurrentPrice() external view returns (uint256) {
        return pricePerStage[currentStage];
    }

    /// @notice Returns amount of tokens sold on current stage
    function getSoldOnCurrentStage() external view returns (uint256) {
        return totalTokensSold - ((currentStage == 0) ? 0 : limitPerStage[currentStage - 1]);
    }

    /// @notice Returns presale last stage token amount limit
    function getTotalPresaleAmount() external view returns (uint256) {
        return limitPerStage[MAX_STAGE_INDEX];
    }

    /// @notice Returns total price of sold tokens
    function totalSoldPrice() external view returns (uint256) {
        return _calculatePriceInBUSDForConditions(totalTokensSold, 0, 0);
    }

    /// @notice Helper function to calculate price in BNB and BUSD for given amount
    /// @param _amount - Amount of tokens to buy
    /// @return priceInBNB - price for passed amount of tokens in BNB in 1e18 format
    /// @return priceInBUSD - price for passed amount of tokens in BUSD in 1e18 format
    function getPrice(uint256 _amount) public view returns (uint256 priceInBNB, uint256 priceInBUSD) {
        if (_amount + totalTokensSold > limitPerStage[MAX_STAGE_INDEX])
            revert PresaleLimitExceeded(limitPerStage[MAX_STAGE_INDEX] - totalTokensSold);
        priceInBUSD = _calculatePriceInBUSDForConditions(_amount, currentStage, totalTokensSold);

        (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Stale price");
        require(updatedAt >= block.timestamp - 3 hours, "Stale price");
        require(price > 0, "Invalid price");
        priceInBNB = (priceInBUSD * 1e8) / uint256(price);
    }

    /// @notice For sending BNB from contract
    /// @param _recipient - Recipient address
    /// @param _bnbAmount - Amount of BNB to send in wei
    function _sendValue(address payable _recipient, uint256 _bnbAmount) internal {
        require(address(this).balance >= _bnbAmount, "Low balance");
        (bool success, ) = _recipient.call{ value: _bnbAmount }("");
        require(success, "BNB Payment failed");
    }

    /// @notice Recursively calculate BUSD cost for specified conditions
    /// @param _amount           - Amount of tokens to calculate price
    /// @param _currentStage     - Starting stage to calculate price
    /// @param _totalTokensSold  - Starting total token sold amount to calculate price
    function _calculatePriceInBUSDForConditions(
        uint256 _amount,
        uint256 _currentStage,
        uint256 _totalTokensSold
    ) internal view returns (uint256 cost) {
        if (_totalTokensSold + _amount <= limitPerStage[_currentStage]) {
            cost = _amount * pricePerStage[_currentStage];
        } else {
            uint256 currentStageAmount = limitPerStage[_currentStage] - _totalTokensSold;
            uint256 nextStageAmount = _amount - currentStageAmount;
            cost =
                currentStageAmount *
                pricePerStage[_currentStage] +
                _calculatePriceInBUSDForConditions(nextStageAmount, _currentStage + 1, limitPerStage[_currentStage]);
        }

        return cost;
    }

    /// @notice Calculate current stage index from total tokens sold amount
    function _getStageByTotalSoldAmount() internal view returns (uint8) {
        uint8 stageIndex = MAX_STAGE_INDEX;
        uint256 totalTokensSold_ = totalTokensSold;
        while (stageIndex > 0) {
            if (limitPerStage[stageIndex - 1] <= totalTokensSold_) break;
            stageIndex -= 1;
        }
        return stageIndex;
    }
}

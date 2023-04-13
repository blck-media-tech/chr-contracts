// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPresale {
    event SaleTimeUpdated(
        uint256 saleStartTime,
        uint256 saleEndTime,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 amount,
        uint256 totalCostInUsd,
        uint256 totalCostInETH,
        string indexed referrerId,
        uint256 timestamp
    );

    /// @notice Function can not be called now
    error InvalidTimeframe();

    /// @notice Trying to buy 0 tokens
    error BuyAtLeastOneToken();

    /// @notice Passed amount is more than amount of tokens remaining for presale
    /// @param tokensRemains - amount of tokens remaining for presale
    error PresaleLimitExceeded(uint256 tokensRemains);

    /// @notice User is in blacklist
    error YouAreInBlacklist();

    /// @notice If zero address was passed
    /// @param contractName - name indicator of the corresponding contract
    error ZeroAddress(string contractName);

    /// @notice Passed amount of ETH is not enough to buy requested amount of tokens
    /// @param sent - amount of ETH was sent
    /// @param expected - amount of ETH necessary to buy requested amount of tokens
    error NotEnoughETH(uint256 sent, uint256 expected);

    /// @notice Provided allowance is not enough to buy requested amount of tokens
    /// @param provided - amount of allowance provided to the contract
    /// @param expected - amount of USDT necessary to buy requested amount of tokens
    error NotEnoughAllowance(uint256 provided, uint256 expected);

    /// @notice User already claimed bought tokens
    error AlreadyClaimed();

    /// @notice No tokens were purchased by this user
    error NothingToClaim();


}

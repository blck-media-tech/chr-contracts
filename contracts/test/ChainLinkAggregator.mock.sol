//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/IChainlinkPriceFeed.sol";

contract ChainLinkAggregatorMock is IChainlinkPriceFeed {
    int256 price = 1500;

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 1;
        answer = price * 10 ** 6;
        startedAt = 2;
        updatedAt = block.timestamp;
        answeredInRound = 4;
    }
}

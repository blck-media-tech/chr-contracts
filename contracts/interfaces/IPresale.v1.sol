// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPresaleV1 {
    function totalTokensSold() external returns(uint256);

    function currentStage() external returns(uint8);

    function purchasedTokens() external returns(uint256);
}

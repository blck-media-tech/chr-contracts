// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPresaleV1 {
    function totalTokensSold() external view returns(uint256);

    function currentStage() external view returns(uint8);

    function purchasedTokens(address _user) external view returns(uint256);

    function paused() external view returns(bool);
}

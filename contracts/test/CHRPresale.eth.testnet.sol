// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../CHRPresale.eth.sol";
import "../openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract CHRPresaleETHTestnet is CHRPresaleETH {
    using SafeERC20 for IERC20;

    constructor(
        address _saleToken,
        address _oracle,
        address _busd,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint32[12] memory _limitPerStage,
        uint64[12] memory _pricePerStage
    ) CHRPresaleETH(_saleToken, _oracle, _busd, _saleStartTime, _saleEndTime, _limitPerStage, _pricePerStage) {}

    function t_resetUser(address _user) public {
        hasClaimed[_user] = false;
        purchasedTokens[_user] = 0;
    }

    function t_claimAndReset() external whenNotPaused {
        if (block.timestamp < claimStartTime || claimStartTime == 0) revert InvalidTimeframe();
        if (hasClaimed[_msgSender()]) revert AlreadyClaimed();
        uint256 amount = purchasedTokens[_msgSender()];
        if (amount == 0) revert NothingToClaim();
        hasClaimed[_msgSender()] = true;
        IERC20(saleToken).safeTransfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        t_resetUser(_msgSender());
    }
}

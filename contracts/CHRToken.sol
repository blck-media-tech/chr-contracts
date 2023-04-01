// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CHRToken is ERC20, Ownable {
    constructor(uint256 _initialSupply, uint256 _cap)
    ERC20("Chancer", "CHR")
    Ownable() {
        _mint(msg.sender, _initialSupply * 10**decimals());
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

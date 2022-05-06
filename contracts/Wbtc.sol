// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Wbtc is ERC20 {
    constructor() ERC20("Wrapped BTC", "WBTC") {
        _mint(msg.sender, 5000);
    }
}
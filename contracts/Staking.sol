// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    address public owner;
    mapping(string => address) public whitelistedCoin;
    mapping(address => mapping(string => uint256)) public stakingBalance;
    
    constructor() {
        owner = msg.sender;
    }

    function whitelistCoin(string memory _coin, address _coinAddress) external {
        require(msg.sender == owner, 'Only owner can whitelist coins');
        whitelistedCoin[_coin] = _coinAddress;
    }

    function depositCoin(string memory _coin, uint256 _amount) external {
        require(_amount > 0, 'Amount cannot be zero');
        IERC20 wbtc = IERC20(whitelistedCoin[_coin]);
        uint256 available = wbtc.balanceOf(msg.sender);
        require(available >= _amount, 'Insufficient coin balance');
        stakingBalance[msg.sender][_coin] += _amount;
        IERC20(whitelistedCoin[_coin]).transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawCoin(string memory _coin, uint256 _amount) external {
        require(_amount > 0, 'Amount cannot be zero');
        require(stakingBalance[msg.sender][_coin] >= _amount, 'Insufficient coin staking balance');

        stakingBalance[msg.sender][_coin] -= _amount;
        IERC20(whitelistedCoin[_coin]).transfer(msg.sender, _amount);
    }
}
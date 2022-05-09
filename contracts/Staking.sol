// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardsToken.sol";

contract Staking is Ownable {
    RewardsToken public rewardsToken;
    mapping(string => address) public whitelistedCoin;
    mapping(address => mapping(string => uint256)) public stakingBalance;
    
    constructor() {
        rewardsToken = new RewardsToken();
    }

    function whitelistCoin(string memory _coin, address _coinAddress) external onlyOwner {
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

    

    // Access Functions
    function grantRDSRole(bytes32 _role, address _account) external onlyOwner {
        IAccessControlEnumerable(rewardsToken).grantRole(_role, _account);
    }

    function revokeRDSRole(bytes32 _role, address _account) external onlyOwner {
        IAccessControlEnumerable(rewardsToken).revokeRole(_role, _account);
    }

    function getRDSRoleCount(bytes32 _role) view external returns(uint256) {
        return IAccessControlEnumerable(rewardsToken).getRoleMemberCount(_role);
    }
}
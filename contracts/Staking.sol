// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardsToken.sol";

contract Staking is Ownable {
    RewardsToken public rewardsToken;
    IERC20 public stakingToken;

    uint256 public rewardRate = 1e14; // Per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public _totalSupply;

    // userAddress => stakingBalance
    mapping(address => uint256) public balances;
    // userAddress => rewardsBalance
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;

    // Events
    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event RewardsPaid(address indexed to, uint256 amount);
    
    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = new RewardsToken();
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, 'Amount cannot be zero');
        uint256 available = stakingToken.balanceOf(msg.sender);
        require(available >= _amount, 'Insufficient coin balance');
        _totalSupply += _amount;
        balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, 'Amount cannot be zero');
        require(balances[msg.sender] >= _amount, 'Nothing to unstake');
        _totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Unstake(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, 'Reward must be greater than 0 to withdraw');
        rewards[msg.sender] = 0;
        rewardsToken.mint(msg.sender, reward);
        emit RewardsPaid(msg.sender, reward);
    }

    function rewardPerToken() public view returns(uint256) {
        if(_totalSupply == 0) {
            return 0;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns(uint256) {
        return ((balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    // Modifiers
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    // Restricted functions
    function changeStakingCoinAddress(address _coinAddress) external onlyOwner {
        stakingToken = IERC20(_coinAddress);
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
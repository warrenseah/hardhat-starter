// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardsToken.sol";

contract Staking is Ownable {
    RewardsToken public rewardsToken;
    address public paymentToken;

    // userAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;
    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;
    // userAddress => timestamp
    mapping(address => uint256) public startTime;
    // userAddress => rewardsBalance
    mapping(address => uint256) public rewardsBalance;

    // Events
    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);
    
    constructor() {
        rewardsToken = new RewardsToken();
    }

    function changePaymentAddress(address _coinAddress) external onlyOwner {
        paymentToken = _coinAddress;
    }

    function depositCoin(uint256 _amount) external onlyAcceptedToken {
        require(_amount > 0, 'Amount cannot be zero');
        IERC20 token = IERC20(paymentToken);
        uint256 available = token.balanceOf(msg.sender);
        require(available >= _amount, 'Insufficient coin balance');

        if(isStaking[msg.sender] == true) {
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            rewardsBalance[msg.sender] += toTransfer;
        }

        stakingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        IERC20(paymentToken).transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount);
    }

    function withdrawCoin(uint256 _amount) external {
        require(_amount > 0, 'Amount cannot be zero');
        require(stakingBalance[msg.sender] >= _amount, 'Nothing to unstake');

        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        delete startTime[msg.sender]; // bug fix

        stakingBalance[msg.sender] -= _amount;
        IERC20(paymentToken).transfer(msg.sender, _amount);
        rewardsBalance[msg.sender] += yieldTransfer;

        if(stakingBalance[msg.sender] == 0) {
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, _amount);

    }

    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);
        require(toTransfer > 0, "Cannot withdraw 0");
        require(rewardsBalance[msg.sender] > 0, "Nothing to withdraw");
        
        uint256 oldBalance = rewardsBalance[msg.sender];
        rewardsBalance[msg.sender] = 0;
        toTransfer += oldBalance;

        delete startTime[msg.sender];
        rewardsToken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
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

    // Modifiers
    modifier onlyAcceptedToken() {
        require(paymentToken != address(0), "Must only work with a accepted payment token");
        _;
    }

    // Helper functions

    function _calculateYieldTime(address user) public view returns(uint256) {
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns(uint256) {
        uint256 time = _calculateYieldTime(user) * 10**18;
        uint256 dayInSeconds = 86400;
        uint256 timeInDay = time / dayInSeconds;
        uint256 rate = 1;
        uint256 totalStakingPool = IERC20(paymentToken).balanceOf(address(this));
        uint256 rawYield = (stakingBalance[msg.sender] / totalStakingPool * timeInDay * rate) / 10**18;
        return rawYield;
    }
}
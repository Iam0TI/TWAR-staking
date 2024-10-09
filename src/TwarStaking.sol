// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {IERC20} from "./interface/IERC20.sol";
import {TwarStakingError, TwarStakingEvent, TwarStakingLib} from "./utils.sol";

contract TwarStaking {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    address public owner;

    // Duration of rewards to be paid for -> seconds
    uint256 public rewardDuraton;

    // The Time Staking (block.timestamp) +  duration
    uint256 public rewardFinishTime;
    // Minimum of  block.timestamp and rewardFinishTime
    uint256 public lastRewardUpdatedTIme;
    // Reward to be paid  per second
    uint256 public rewardRate;
    // Amount of   Staking tokens staked
    uint256 public totalAmountStaked;

    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;

    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    // User address => amount staked
    mapping(address => uint256) public usersBalance;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = TwarStakingLib.rewardPerToken(
            totalAmountStaked, rewardPerTokenStored, rewardRate, lastTimeForReward(), lastRewardUpdatedTIme
        );
        lastRewardUpdatedTIme = lastTimeForReward();

        if (_account != address(0)) {
            rewards[_account] = TwarStakingLib.earned(
                usersBalance[_account], rewardPerTokenStored, userRewardPerTokenPaid[_account], rewards[_account]
            );
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, TwarStakingError.NotOwner());
        _;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, TwarStakingError.Staking_ZeroAmount());

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        usersBalance[msg.sender] += _amount;

        totalAmountStaked += _amount;
    }

    function withdraw(uint256 _amount) public updateReward(msg.sender) {
        require(_amount > 0, TwarStakingError.Withdraw_ZeroAmount());

        usersBalance[msg.sender] -= _amount;
        totalAmountStaked -= _amount;

        stakingToken.transfer(msg.sender, _amount);
    }

    function withdrawRewards() public updateReward(msg.sender) returns (uint256 reward) {
        reward = rewards[msg.sender];

        require(reward > 0, TwarStakingError.Reward_ZeroAmount());

        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);

        emit TwarStakingEvent.ClaimedReward(msg.sender, reward);
    }

    function exit() public {
        uint256 reward = withdrawRewards();
        withdraw(usersBalance[msg.sender]);
        emit TwarStakingEvent.ExitPool(msg.sender, usersBalance[msg.sender], reward);
    }

    function updateRewardRate(uint256 _poolReward) external onlyOwner updateReward(address(0)) {
        require(rewardDuraton > 0, TwarStakingError.DurationisZero());
        rewardToken.transferFrom(msg.sender, address(this), _poolReward);
        //  for case when rewardFinishTime  is 0 or  as ended
        if (block.timestamp > rewardFinishTime) {
            rewardRate = _poolReward / rewardDuraton;
            if (rewardFinishTime == 0) emit TwarStakingEvent.StakingStarted(msg.sender, _poolReward, rewardDuraton);
        }
        // if a staking period is till active
        else {
            uint256 remainingPeriod = rewardFinishTime - block.timestamp;
            uint256 remainingReward = rewardRate * remainingPeriod;

            rewardRate = (remainingReward + _poolReward) / rewardDuraton;

            emit TwarStakingEvent.StakingRewardIncreased(msg.sender, rewardRate, remainingPeriod);
        }

        //Ensure the provided reward amount is not more than the balance in the contract.
        require(rewardRate > 0, TwarStakingError.RewardRate_ZeroAmount());
        uint256 poolrewardAmount = rewardRate * rewardDuraton;
        require(poolrewardAmount <= rewardToken.balanceOf(address(this)), TwarStakingError.PoolReward_TooMuch());

        rewardFinishTime = rewardDuraton + block.timestamp;
        lastRewardUpdatedTIme = block.timestamp;
    }

    function setRewardDuraton(uint256 _duration) external onlyOwner {
        require(_duration > 0, TwarStakingError.DurationisZero());

        require(rewardFinishTime < block.timestamp, TwarStakingError.StakingIsActive());

        rewardDuraton = _duration;
    }

    function earned(address _account) external view returns (uint256 earnings) {
        uint256 rewardPerToken = TwarStakingLib.rewardPerToken(
            totalAmountStaked, rewardPerTokenStored, rewardRate, lastTimeForReward(), lastRewardUpdatedTIme
        );

        earnings = TwarStakingLib.earned(
            usersBalance[_account], rewardPerToken, userRewardPerTokenPaid[_account], rewards[_account]
        );
    }
    // function earned(address _account) public view returns (uint256) {

    //     return ((usersBalance[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18)
    //         + rewards[_account];
    // }

    // rewardpertoken is 0 when totalAmountStaked  is 0  and when totalAmountStaked is not 0
    // then  rewardpertoken = RJ =  RJ0 + R/T (J-J0) where J is in seconds
    // function rewardPerToken() public view returns (uint256) {
    //     if (totalAmountStaked == 0){
    //         return rewardPerTokenStored;
    //     }else {
    //         rewardPerTokenStored + (rewardRate * (lastTimeForReward()- lastRewardUpdatedTIme) * 1e18)/totalAmountStaked;
    //         }
    //}

    function lastTimeForReward() public view returns (uint256) {
        return _min(rewardFinishTime, block.timestamp);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}



// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

library TwarStakingLib {
    
    // The minimum function to return the smaller of two values
    function _min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    // The earned function for calculating rewards
    function earned(
        uint256 userBalance, 
        uint256 rewardPerTokenStored, 
        uint256 userRewardPerTokenPaid, 
      
        uint256 rewards
    ) internal pure returns (uint256) {
        return ((userBalance * (rewardPerTokenStored - userRewardPerTokenPaid)) / 1e18) + rewards;
    }

 // rewardpertoken is 0 when totalAmountStaked  is 0  and when totalAmountStaked is not 0
    // then  rewardpertoken = RJ =  RJ0 + R/T (J-J0) where J is in seconds
    // The rewardPerToken function to calculate the reward rate per token
    function rewardPerToken(
        uint256 totalAmountStaked, 
        uint256 rewardPerTokenStored, 
        uint256 rewardRate, 
        uint256 lastTimeForReward, 
        uint256 lastRewardUpdatedTIme
    ) internal pure returns (uint256) {
        if (totalAmountStaked == 0) {
            return rewardPerTokenStored;
        } else {
            return rewardPerTokenStored + (rewardRate * (lastTimeForReward - lastRewardUpdatedTIme) * 1e18) / totalAmountStaked;
        }
    }
}

library TwarStakingError {
    error Staking_ZeroAmount();
    error Withdraw_ZeroAmount();
    error Reward_ZeroAmount();
    error RewardRate_ZeroAmount();
    error NotOwner();
    error StakingIsActive();
    error DurationisZero();
    error PoolReward_TooMuch();
}

library TwarStakingEvent {
    event Staked(address indexed user, uint256 indexed stakedAmount);
    event WithdrawStake(address indexed user, uint256 indexed amountWithdrawn);
    event ExitPool(address indexed user, uint256 indexed amount, uint256 indexed rewardAmount);
    event ClaimedReward(address indexed user, uint256 indexed UserRewardAmount);
    event StakingStarted(address indexed user, uint256 indexed PoolrewardAmount, uint256 indexed duration);
    event StakingRewardIncreased(
        address indexed user, uint256 indexed newRewardAmount, uint256 indexed remainingPeriod
    );
}

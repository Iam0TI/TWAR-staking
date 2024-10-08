// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

library TwarStakingError {
    error Staking_ZeroAmount();
    error Withdraw_ZeroAmount();
    error Reward_ZeroAmount();
    error RewardRate_ZeroAmount();
    error NotOwner();
    error StakingIsActive();
    error DurationisZero();
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

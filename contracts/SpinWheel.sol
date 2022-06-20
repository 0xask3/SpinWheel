// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SpinWheel is Ownable {
    enum Outcomes {
        BetterLuckNextTime,
        OneMoreSpin,
        TokenReward1,
        TokenReward2,
        TokenReward3
    }

    struct User {
        uint256 lastCalled;
        uint8 count; //To keep track of repeat
        Outcomes lastOutcome; //Last won price
    }

    uint256 public lastRandom;
    uint16[] public chances; //Percentage for each wins
    IERC20 private token; //Price token
    uint256[3] public tokenRewards; //Reward for each win

    mapping(address => User) public users;

    event WheelSpin(address userAdd, uint8 outcome, uint256 lastRandom);

    constructor(address _token) {
        token = IERC20(_token);

        /*Chance work like this : 
        If random num is between 0-400, better luck next time
        If random num is between 401-700, free spin
        Likewise
        */
        chances.push(0);
        chances.push(400);
        chances.push(700);
        chances.push(800);
        chances.push(900);
        chances.push(1000);

        tokenRewards[0] = 10 * 10**18;
        tokenRewards[1] = 100 * 10**18;
        tokenRewards[2] = 1000 * 10**18;
    }

    function setTokenRewards(uint256[3] memory newRewards) external onlyOwner {
        tokenRewards = newRewards;
    }

    function setChances(uint16[] memory newChances) external onlyOwner {
        for (uint8 i = 1; i < newChances.length; i++) {
            require(newChances[i] > newChances[i - 1], "Invalid chance");
            chances[i] = newChances[i];
        }
    }

    function spinWheel() external {
        User storage user = users[msg.sender];

        if (user.lastOutcome == Outcomes.OneMoreSpin) {
            if (user.count >= 4) {
                require(
                    block.timestamp >= user.lastCalled + 48 hours,
                    "Bad luck for you :)"
                );

                user.count = 0;
            }
        } else {
            require(
                block.timestamp >= user.lastCalled + 24 hours,
                "Time limit not expired"
            );
            user.count = 0;
        }

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        lastRandom = seed % 1000;
        handleOutcome(msg.sender);

        user.lastCalled = block.timestamp;
    }

    function handleOutcome(address userAdd) internal {
        uint8 outcome;
        User storage user = users[userAdd];
        uint256 len = chances.length;

        for (uint8 i = 0; i < len - 1; i++) {
            if (lastRandom >= chances[i] && lastRandom < chances[i + 1]) {
                outcome = i;
                break;
            }
        }

        if (outcome == 0) {
            user.lastOutcome = Outcomes.BetterLuckNextTime;
        } else if (outcome == 1) {
            user.count++;
            user.lastOutcome = Outcomes.OneMoreSpin;
        } else if (outcome == 2) {
            user.lastOutcome = Outcomes.TokenReward1;
            token.transfer(userAdd, tokenRewards[0]);
        } else if (outcome == 3) {
            user.lastOutcome = Outcomes.TokenReward2;
            token.transfer(userAdd, tokenRewards[1]);
        } else if (outcome == 4) {
            user.lastOutcome = Outcomes.TokenReward3;
            token.transfer(userAdd, tokenRewards[2]);
        }

        emit WheelSpin(userAdd, outcome, lastRandom);
    }
}

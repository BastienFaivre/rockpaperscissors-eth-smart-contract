// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    uint public constant MIN_BET = 1 ether; // 1e18 wei
    uint public constant REVEAL_TIMEOUT = 10 minutes;
    uint public initialBet;
    uint private firstRevealTimeStamp;

    enum Choices {
        None,
        Rock,
        Paper,
        Scissors
    }
    enum Outcomes {
        None,
        Draw,
        Player1,
        Player2
    }

    address payable player1;
    address payable player2;

    bytes32 private encryptedChoicePlayer1;
    bytes32 private encryptedChoicePlayer2;

    modifier validBet() {
        require(msg.value >= MIN_BET, "Bet must be at least 1 ether");
        require(
            initialBet == 0 || msg.value >= initialBet,
            "Bet must be bigger than the initial bet"
        );
        _;
    }

    modifier notAlreadyRegistered() {
        require(
            msg.sender != player1 && msg.sender != player2,
            "You are already registered"
        );
        _;
    }

    function register() public payable validBet notAlreadyRegistered returns (uint) {
        if (player1 == address(0x0)) {
            player1 = payable(msg.sender);
            initialBet = msg.value;
            return 1;
        } else if (player2 == address(0x0)) {
            player2 = payable(msg.sender);
            return 2;
        }
        return 0;
    }
}

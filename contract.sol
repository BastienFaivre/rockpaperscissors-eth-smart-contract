// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    uint public constant MIN_BET = 1 ether; // 1e18 wei
    uint public constant REVEAL_TIMEOUT = 10 minutes;
    uint public initialBet;
    uint private firstRevealTimestamp;

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

    Choices private choicePlayer1;
    Choices private choicePlayer2;

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

    function register()
        public
        payable
        validBet
        notAlreadyRegistered
        returns (uint)
    {
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

    modifier isRegistered() {
        require(
            msg.sender == player1 || msg.sender == player2,
            "You are not registered"
        );
        _;
    }

    function submitChoice(
        bytes32 encryptedChoice
    ) public isRegistered returns (bool) {
        if (msg.sender == player1 && encryptedChoicePlayer1 == 0x0) {
            encryptedChoicePlayer1 = encryptedChoice;
        } else if (msg.sender == player2 && encryptedChoicePlayer2 == 0x0) {
            encryptedChoicePlayer2 = encryptedChoice;
        } else {
            return false;
        }
        return true;
    }

    function getEnumValue(string memory choice) private pure returns (Choices) {
        if (keccak256(abi.encodePacked(choice)) == keccak256("rock")) {
            return Choices.Rock;
        } else if (keccak256(abi.encodePacked(choice)) == keccak256("paper")) {
            return Choices.Paper;
        } else if (
            keccak256(abi.encodePacked(choice)) == keccak256("scissors")
        ) {
            return Choices.Scissors;
        }
        return Choices.None;
    }

    modifier commitPhaseEnded() {
        require(
            encryptedChoicePlayer1 != 0x0 && encryptedChoicePlayer2 != 0x0,
            "Commit phase has not ended yet"
        );
        _;
    }

    function revealChoice(
        string memory choice_
    ) public isRegistered commitPhaseEnded returns (Choices) {
        bytes32 encryptedChoice = sha256(abi.encodePacked(choice_));
        Choices choice = getEnumValue(choice_);

        if (choice == Choices.None) {
            return Choices.None;
        }

        if (
            msg.sender == player1 && encryptedChoice == encryptedChoicePlayer1
        ) {
            choicePlayer1 = choice;
        } else if (
            msg.sender == player2 && encryptedChoice == encryptedChoicePlayer2
        ) {
            choicePlayer2 = choice;
        } else {
            return Choices.None;
        }

        if (firstRevealTimestamp == 0) {
            firstRevealTimestamp = block.timestamp;
        }

        return choice;
    }

    function pay(
        address payable addr1,
        address payable addr2,
        uint betPlayer1,
        Outcomes outcome
    ) private {
        if (outcome == Outcomes.Player1) {
            addr1.transfer(address(this).balance);
        } else if (outcome == Outcomes.Player2) {
            addr2.transfer(address(this).balance);
        } else if (outcome == Outcomes.Draw) {
            addr1.transfer(betPlayer1);
            addr2.transfer(address(this).balance);
        }
    }

    function reset() private {
        initialBet = 0;
        firstRevealTimestamp = 0;
        player1 = payable(address(0x0));
        player2 = payable(address(0x0));
        encryptedChoicePlayer1 = 0x0;
        encryptedChoicePlayer2 = 0x0;
        choicePlayer1 = Choices.None;
        choicePlayer2 = Choices.None;
    }

    modifier revealPhaseEnded() {
        require(
            (choicePlayer1 != Choices.None && choicePlayer2 != Choices.None) ||
                (firstRevealTimestamp != 0 &&
                    block.timestamp >= firstRevealTimestamp + REVEAL_TIMEOUT),
            "Reveal phase has not ended yet"
        );
        _;
    }

    function getOutcome() public revealPhaseEnded returns (Outcomes) {
        Outcomes outcome = Outcomes.None;

        if (choicePlayer1 == choicePlayer2) {
            outcome = Outcomes.Draw;
        } else if (
            (choicePlayer1 == Choices.Rock &&
                choicePlayer2 == Choices.Scissors) ||
            (choicePlayer1 == Choices.Paper && choicePlayer2 == Choices.Rock) ||
            (choicePlayer1 == Choices.Scissors &&
                choicePlayer2 == Choices.Paper) ||
            (choicePlayer1 != Choices.None && choicePlayer2 == Choices.None)
        ) {
            outcome = Outcomes.Player1;
        } else {
            outcome = Outcomes.Player2;
        }

        reset();
        pay(player1, player2, initialBet, outcome);

        return outcome;
    }
}

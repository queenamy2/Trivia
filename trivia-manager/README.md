# Trivia Game Smart Contract

A decentralized trivia game platform built on Stacks blockchain using Clarity smart contract language. This contract enables users to create and participate in trivia games with STX stakes.

## Overview

The Trivia Game Smart Contract provides a trustless platform for creating and participating in trivia games. Game creators can set questions with stakes, and participants can submit answers while adding to the prize pool. The contract ensures fair gameplay and secure prize distribution.

## Features

- **Game Creation**: Users can create trivia games with custom questions and stakes
- **Secure Participation**: Players can submit answers with additional stakes
- **Prize Pool Management**: Automatic handling of STX stakes and prize distribution
- **Anti-Cheat Mechanisms**: Prevention of duplicate answers and game manipulation
- **Emergency Controls**: Administrative functions for emergency situations
- **Ownership Management**: Secure contract ownership transfer capabilities

## Functions

### Public Functions

1. **create-trivia-game**
   - Create a new trivia game with initial stake
   - Parameters:
     - trivia-question: (string-utf8 256)
     - correct-answer: (string-utf8 256)
     - initial-stake: uint
   - Returns: game ID (uint)

2. **submit-participant-answer**
   - Submit an answer to an existing game
   - Parameters:
     - trivia-game-id: uint
     - participant-answer: (string-utf8 256)
     - participation-stake: uint
   - Returns: boolean

3. **finalize-trivia-game**
   - End a game and distribute prizes
   - Parameters:
     - trivia-game-id: uint
   - Returns: boolean

### Read-Only Functions

1. **get-trivia-game-information**
   - Retrieve game details
   - Parameters:
     - trivia-game-id: uint
   - Returns: game information

2. **get-participant-submission**
   - Get participant's submitted answer
   - Parameters:
     - trivia-game-id: uint
     - participant-address: principal
   - Returns: submission details

### Administrative Functions

1. **transfer-contract-ownership**
   - Transfer contract ownership
   - Parameters:
     - new-administrator: principal
   - Returns: boolean

2. **emergency-game-shutdown**
   - Emergency shutdown of a game
   - Parameters:
     - trivia-game-id: uint
   - Returns: boolean

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Trivia game already exists |
| u102 | Trivia game not found |
| u103 | Invalid stake amount |
| u104 | Trivia game ended |
| u105 | Duplicate answer |
| u106 | Insufficient STX balance |

## Security Considerations

1. **Access Control**
   - Only game creators can finalize games
   - Only contract administrator can perform emergency actions
   - Participants can only submit one answer per game

2. **Financial Security**
   - Safe STX transfer handling
   - Prize pool protection
   - Stake validation

3. **State Management**
   - Game state validation
   - Proper error handling
   - Protected administrative functions

## Usage Examples

1. Creating a Trivia Game
```clarity
(contract-call? .trivia-game create-trivia-game 
    "What is the capital of France?" 
    "Paris" 
    u100)
```

2. Submitting an Answer
```clarity
(contract-call? .trivia-game submit-participant-answer 
    u1 
    "Paris" 
    u50)
```

3. Finalizing a Game
```clarity
(contract-call? .trivia-game finalize-trivia-game u1)
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
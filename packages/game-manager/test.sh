#!/bin/bash

my_function() {
    ID=$(shuf -i 1-100 -n 1)
    
    # Creating a new game
    echo "{\"game_id\": \"$ID\", \"game_type\": \"guess-the-number\", \"users\": [\"user1\", \"user2\"]}" | nats request zane.matchmake.initialize
    
    # Player 1 selects 0
    echo '{"user": "user1", "properties": {"number": "0"}}' | nats request zane.game.$ID
    
    # Player 2 selects 9
    echo '{"user": "user2", "properties": {"number": "9"}}' | nats request zane.game.$ID
    
    # Player 1 guesses 1
    echo '{"user": "user1", "properties": {"number": "1"}}' | nats request zane.game.$ID
    
    # Player 2 guesses 8
    echo '{"user": "user2", "properties": {"number": "8"}}' | nats request zane.game.$ID
}
my_function

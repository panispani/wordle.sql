#!/bin/bash

# Initialize the game
psql -d postgres -f wordle.sql > /dev/null 2>&1

# Start the game with an empty input to get the welcome message
psql -At -d postgres -c "SELECT play_game('');"

# Game loop
while read guess; do # Read user input
    psql -At -d postgres -c "SELECT play_game('$guess');" # Run game with the input guess
done

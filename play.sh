#!/bin/bash

# Initialize the game
psql -d postgres -f wordle.sql > /dev/null 2>&1

# Game loop
while true; do
    read guess
    echo "SELECT play_game('${guess}');" > query.sql
    psql -At -d postgres -f query.sql
done

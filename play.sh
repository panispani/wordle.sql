#!/bin/bash

# Initialize the game
psql -d postgres -f wordle.sql > /dev/null 2>&1

echo "Welcome to SQL Wordle!"
echo "Guess the 5-letter word. Type EXIT to quit."

# Game loop
while true; do
    echo -n "Your guess: "
    read guess

    # Convert input to lowercase for comparison
    if [[ "$(echo "$guess" | tr '[:upper:]' '[:lower:]')" == "exit" ]]; then
        echo "👋 Bye!"
        exit 0
    fi

    # Convert to uppercase before passing to SQL
    uppercase_guess=$(echo "$guess" | tr '[:lower:]' '[:upper:]')
    echo "SELECT play_game('${uppercase_guess}');" > query.sql
    psql -At -d postgres -f query.sql
done

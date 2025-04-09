# worlde.sql

## Run on Mac

Install PostgreSQL

```bash
brew install postgresql@14
```

Run postgress

```bash
# Option 1: Start in background and keep it there
brew services start postgresql@14
# Option 2: Start and stop it manually
pg_ctl -D /opt/homebrew/var/postgresql@14 start
pg_ctl -D /opt/homebrew/var/postgresql@14 stop # when you are done
```

Check if it's running

```bash
psql postgres # type \q to quit
```

## Misc

Inspect tables

```bash
psql postgres
```

```sql
-- View word dictionary
SELECT * FROM words LIMIT 10;
-- View current secret word
SELECT * FROM secret_word;
-- View all guesses so far with feedback
SELECT
    guess,
    render_feedback(guess) AS feedback,
    created_at
FROM guesses
ORDER BY created_at;
-- Check internal game state
SELECT * FROM game_state;
-- Check high score
SELECT * FROM high_score;
```

## Run in Docker container

Build the image:

```bash
docker build -t sql-wordle .
```

Run the game:

```
docker run --rm -it sql-wordle
```

## Run this

One liner:

```bash
psql -d postgres -f wordle.sql > /dev/null 2>&1; psql -At -d postgres -c "SELECT play_game('')"; while read g; do psql -At -d postgres -c "SELECT play_game('$g')"; done
```

A more readable but minimal game loop in bash

```bash
./play.sh
```

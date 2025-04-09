-----------------
-- INITIAL SETUP
-----------------

-- Clean up old state
DROP TABLE IF EXISTS words;
DROP TABLE IF EXISTS secret_word;
DROP TABLE IF EXISTS guesses;
DROP TABLE IF EXISTS high_score;
DROP TABLE IF EXISTS game_state;

-- Word list
CREATE TABLE words (
    word TEXT PRIMARY KEY CHECK (LENGTH(word) = 5)
);
-- PostgreSQL specific command
\copy words FROM 'words.txt'

-- Game state
CREATE TABLE game_state (
    state TEXT DEFAULT 'INITIAL', -- INITIAL, PLAYING, WON, LOST
    attempts_left INT DEFAULT 6,
    is_high_score BOOLEAN DEFAULT FALSE
);

-- Tracks the current secret word
CREATE TABLE secret_word (
    word TEXT CHECK (LENGTH(word) = 5),
    started_at TIMESTAMP DEFAULT NOW()
);

-- All guesses for current game
CREATE TABLE guesses (
    guess TEXT CHECK (LENGTH(guess) = 5),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Scoreboard
CREATE TABLE high_score (
    player_name TEXT,
    guesses INT,
    achieved_at TIMESTAMP DEFAULT NOW()
);

-- Initialize game state
INSERT INTO game_state (state, attempts_left) VALUES ('INITIAL', 6);

-- Start a game with a random word
INSERT INTO secret_word
SELECT word FROM words ORDER BY random() LIMIT 1;







--------------
-- Game engine
--------------

-- Function to generate feedback for a guess
CREATE OR REPLACE FUNCTION generate_feedback(input_guess TEXT, secret_word TEXT)
RETURNS TEXT AS $$
DECLARE
    feedback TEXT := '';
    i INT;
    letter CHAR;
BEGIN
    FOR i IN 1..5 LOOP
        letter := SUBSTRING(LOWER(input_guess), i, 1);

        IF SUBSTRING(secret_word, i, 1) = letter THEN
            feedback := feedback || '🟩';
        ELSIF POSITION(letter IN secret_word) > 0 THEN
            feedback := feedback || '🟨';
        ELSE
            feedback := feedback || '⬛';
        END IF;
    END LOOP;
    
    RETURN feedback;
END;
$$ LANGUAGE plpgsql;

-- Function to restart the game
CREATE OR REPLACE FUNCTION restart_game()
RETURNS TEXT AS $$
BEGIN
    DELETE FROM secret_word;
    DELETE FROM guesses;
    
    -- Update game state
    UPDATE game_state SET state = 'PLAYING', attempts_left = 6, is_high_score = FALSE;
    
    -- Insert new random word
    INSERT INTO secret_word
    SELECT w.word FROM words w ORDER BY random() LIMIT 1;
    
    RETURN '🎮 New game started! You have 6 attempts to guess the 5-letter word.
Your guess: ';
END;
$$ LANGUAGE plpgsql;

-- Function to get welcome message
CREATE OR REPLACE FUNCTION welcome_message()
RETURNS TEXT AS $$
BEGIN
    -- Change state from INITIAL to PLAYING
    UPDATE game_state SET state = 'PLAYING';
    
    RETURN '🎮 Welcome to SQL Wordle!
You have 6 attempts to guess a 5-letter word.
Type RESTART at any time to start a new game.
Press Ctrl+C in the shell to quit.

Your guess: ';
END;
$$ LANGUAGE plpgsql;

-- Function to get high score information
CREATE OR REPLACE FUNCTION get_high_score_info()
RETURNS TEXT AS $$
DECLARE
    best_score RECORD;
BEGIN
    SELECT player_name, guesses, achieved_at INTO best_score
    FROM high_score
    ORDER BY guesses ASC, achieved_at DESC
    LIMIT 1;

    IF best_score IS NULL THEN
        RETURN 'No high scores yet!';
    END IF;

    RETURN '🏆 High Score: ' || best_score.player_name || ' (' || best_score.guesses || ' guesses)';
END;
$$ LANGUAGE plpgsql;

-- Main game function
CREATE OR REPLACE FUNCTION play_game(input TEXT)
RETURNS TEXT AS $$
DECLARE
    word TEXT;
    current_state TEXT;
    attempts INT;
    is_high BOOLEAN;
    feedback TEXT := '';
    guess_count INT;
    best_guess INT;
    high_score_info TEXT;
BEGIN
    -- Convert input to uppercase for consistent handling
    input := UPPER(input);

    -- Get current game state
    SELECT state, attempts_left, is_high_score INTO current_state, attempts, is_high
    FROM game_state;
    
    -- Get high score info
    high_score_info := get_high_score_info();

    -- Initial state (first run)
    IF current_state = 'INITIAL' THEN
        RETURN welcome_message();
    END IF;
    
    -- RESTART command works in any state
    IF input = 'RESTART' THEN
        RETURN restart_game();
    END IF;
    
    -- Check if game is over (WON or LOST states)
    IF current_state = 'WON' THEN
        -- In WON state, we can only restart or save name if high score
        IF is_high = TRUE THEN
            SELECT COUNT(*) INTO guess_count FROM guesses;
            INSERT INTO high_score(player_name, guesses)
            VALUES (input, guess_count);
            
            -- Update state to indicate name was saved
            UPDATE game_state SET is_high_score = FALSE;
            high_score_info := get_high_score_info();
            RETURN 'Score saved! ' || high_score_info || '
Type RESTART to play again.';
        ELSE
            RETURN 'You already won! ' || high_score_info || '
Type RESTART to play again.';
        END IF;
    END IF;
    
    IF current_state = 'LOST' THEN
        RETURN 'Game over! Better luck next time! ' || high_score_info || '
Type RESTART to play again.';
    END IF;
    
    -- PLAYING state logic
    
    -- Validate input length
    IF LENGTH(input) != 5 THEN
        RETURN '❌ Invalid guess. Enter a 5-letter word.

Your guess: ';
    END IF;
    
    -- Validate word exists in dictionary
    IF NOT EXISTS (SELECT 1 FROM words WHERE words.word = LOWER(input)) THEN
        RETURN '❌ Word not found in dictionary. Try again.

Your guess: ';
    END IF;
    
    -- Get secret word
    SELECT sw.word INTO word FROM secret_word sw;
    
    -- Insert guess
    INSERT INTO guesses (guess) VALUES (LOWER(input));
    
    -- Update attempts left
    UPDATE game_state SET attempts_left = attempts_left - 1;
    SELECT attempts_left INTO attempts FROM game_state;
    
    -- Check for win
    IF LOWER(input) = word THEN
        -- Get number of guesses used
        SELECT COUNT(*) INTO guess_count FROM guesses;
        
        -- Check if it's the best score
        SELECT MIN(guesses) INTO best_guess FROM high_score;
        
        -- Update game state for win
        IF best_guess IS NULL OR guess_count < best_guess THEN
            UPDATE game_state SET state = 'WON', is_high_score = TRUE;
            RETURN '🟩🟩🟩🟩🟩 🎉 Congratulations! You won in ' || guess_count || ' guesses!
That''s a high score! Enter your name: ';
        ELSE
            UPDATE game_state SET state = 'WON', is_high_score = FALSE;
            RETURN '🟩🟩🟩🟩🟩 🎉 Congratulations! You won in ' || guess_count || ' guesses!
' || high_score_info || '
Type RESTART to play again.';
        END IF;
    END IF;
    
    -- Generate feedback for guess
    feedback := generate_feedback(input, word);
    
    -- Check if out of attempts
    IF attempts <= 0 THEN
        UPDATE game_state SET state = 'LOST';
        RETURN feedback || ' ❌ Game over! You''re out of attempts.
The word was: ' || word || '
Better luck next time! ' || high_score_info || '
Type RESTART to try again.';
    END IF;
    
    -- Return feedback and prompt for next guess
    RETURN feedback || ' (' || attempts || ' attempts left)

Your guess: ';
END;
$$ LANGUAGE plpgsql;


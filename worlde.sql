-----------------
-- INITIAL SETUP
-----------------

-- Clean up old state
DROP TABLE IF EXISTS words;
DROP TABLE IF EXISTS current_game;
DROP TABLE IF EXISTS guesses;
DROP TABLE IF EXISTS high_scores;

-- Word list
CREATE TABLE words (
    word TEXT PRIMARY KEY CHECK (LENGTH(word) = 5)
);
-- PostgreSQL specific command
\copy words FROM 'data/words.txt'


-- Tracks the current active game
CREATE TABLE current_game (
    word TEXT CHECK (LENGTH(word) = 5), -- secret word
    started_at TIMESTAMP DEFAULT NOW()
);

-- All guesses for current game
CREATE TABLE guesses (
    guess TEXT CHECK (LENGTH(guess) = 5),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Scoreboard
CREATE TABLE high_scores (
    name TEXT,
    guesses INT,
    achieved_at TIMESTAMP DEFAULT NOW()
);

-- Start a game with a random word
INSERT INTO current_game
SELECT word FROM words ORDER BY random() LIMIT 1;





--------------
-- Game engine
--------------

CREATE OR REPLACE FUNCTION play_game(input TEXT)
RETURNS TEXT AS $$
DECLARE
    word TEXT;
    i INT;
    feedback TEXT := '';
    letter CHAR;
    guess_count INT;
    is_new_best BOOLEAN;
    best_guess INT;
BEGIN
    -- Special commands
    IF input = 'RESTART' THEN
        DELETE FROM current_game;
        DELETE FROM guesses;
        INSERT INTO current_game
        SELECT w.word FROM words w ORDER BY random() LIMIT 1;
        RETURN '🎮 New game started! Hint: it''s a 5-letter word.';
    ELSIF input LIKE 'NAME:%' THEN
        SELECT COUNT(*) INTO guess_count FROM guesses;
        INSERT INTO high_scores(name, guesses)
        VALUES (SUBSTRING(input FROM 6), guess_count);
        RETURN '🏆 Score saved! Type RESTART to play again.';
    END IF;

    -- Normal gameplay
    IF LENGTH(input) != 5 THEN
        RETURN '❌ Invalid guess. Enter 5 letters or RESTART.';
    END IF;

    SELECT cg.word INTO word FROM current_game cg;

    SELECT COUNT(*) INTO guess_count FROM guesses;
    IF guess_count >= 6 THEN
        RETURN '❌ You already used 6 guesses. Type RESTART to try again.';
    END IF;

    INSERT INTO guesses (guess) VALUES (LOWER(input));

    IF LOWER(input) = word THEN
        guess_count := guess_count + 1;
        -- Check if it's the best score
        SELECT MIN(guesses) INTO best_guess FROM high_scores;
        is_new_best := best_guess IS NULL OR guess_count < best_guess;

        IF is_new_best THEN
            RETURN '🟩🟩🟩🟩🟩 🎉 You win in ' || guess_count || ' guesses! Enter your name like: NAME:YourName';
        ELSE
            RETURN '🟩🟩🟩🟩🟩 🎉 You win in ' || guess_count || ' guesses! Type RESTART to play again.';
        END IF;
    END IF;

    -- Letter-by-letter feedback
    FOR i IN 1..5 LOOP
        letter := SUBSTRING(LOWER(input), i, 1);

        IF SUBSTRING(word, i, 1) = letter THEN
            feedback := feedback || '🟩';
        ELSIF POSITION(letter IN word) > 0 THEN
            feedback := feedback || '🟨';
        ELSE
            feedback := feedback || '⬛';
        END IF;
    END LOOP;

    guess_count := guess_count + 1;

    IF guess_count >= 6 THEN
        feedback := feedback || ' ❌ You lose. Word was: ' || word || '. Type RESTART to try again.';
    END IF;

    RETURN feedback;
END;
$$ LANGUAGE plpgsql;

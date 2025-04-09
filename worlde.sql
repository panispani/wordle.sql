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






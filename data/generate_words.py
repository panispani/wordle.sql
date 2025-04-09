import nltk
from nltk.corpus import words

# Download the words corpus if not already available
nltk.download("words")

# Get a list of all English words
all_words = words.words()

# Filter for unique 5-letter words
five_letter_words = sorted(
    set(word.lower() for word in all_words if len(word) == 5 and word.isalpha())
)

with open("words.txt", "w") as f:
    for word in five_letter_words:
        f.write(word + "\n")

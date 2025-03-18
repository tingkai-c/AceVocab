class Question {
  final int id;
  final String
  sentence; // The sentence with a blank (e.g., "The cat sat on the ___.")
  final String correctAnswer; // The correct word to fill the blank
  final List<String>
  options; // List of multiple-choice options (doesn't include the correct answer)

  Question({
    required this.id,
    required this.sentence,
    required this.correctAnswer,
    required this.options,
  });

  // Factory constructor to create a Question from a database map
  factory Question.fromMap(Map<String, dynamic> map, List<String> allWords) {
    // 1. Extract data from the map
    final int wordId = map['word_id'] as int;
    final String correctAnswer = map['word'] as String;

    // 2. Generate a sentence (you'll need logic for this)
    final String sentence = _generateSentence(correctAnswer); // Implement this

    // 3. Create distractor options (incorrect choices)
    final List<String> options = _generateOptions(correctAnswer, allWords);

    return Question(
      id: wordId,
      sentence: sentence,
      correctAnswer: correctAnswer,
      options: options,
    );
  }

  // Helper function to generate a sentence (example - adapt to your needs)
  static String _generateSentence(String word) {
    // Simple example (replace with more sophisticated logic)
    switch (word) {
      case 'cat':
        return 'The ___ sat on the mat.';
      case 'dog':
        return 'The ___ barked loudly.';
      case 'happy':
        return 'She felt very ___ today.';
      default:
        return 'This is a sentence about the word "$word".'; // Fallback
    }
  }

  // Helper function to generate options (example)
  static List<String> _generateOptions(
    String correctAnswer,
    List<String> allWords,
  ) {
    // Shuffle the words to get random distractors
    final shuffledWords = List<String>.from(allWords)..shuffle();

    // Create a list to store options
    List<String> options = [];

    // Add the correct answer to the options
    options.add(correctAnswer);

    // Add unique distractor words until you have 3 (or your desired number)
    for (String word in shuffledWords) {
      if (word != correctAnswer && options.length < 4) {
        options.add(word);
      }
      if (options.length >= 4) {
        // Or however many options you want
        break;
      }
    }

    // Shuffle the options so the correct answer isn't always in the same position
    options.shuffle();
    return options;
  }
}

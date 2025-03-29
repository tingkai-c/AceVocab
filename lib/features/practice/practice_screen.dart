import 'package:acevocab/features/common/ui/clickable_text.dart';
import 'package:acevocab/fsrs/models.dart' as fsrs;
import 'package:acevocab/fsrs/word_scheduler.dart';
import 'package:acevocab/utils/browser_utils.dart'; // Import the utility
import 'package:flutter/material.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late WordScheduler _wordScheduler;
  fsrs.Question? _currentQuestion;
  String _feedbackMessage = '';
  bool _answered = false;
  late fsrs.Parameters _parameters; // Although unused, kept as in original
  bool _isLoading = true; // Start in loading state

  @override
  void initState() {
    super.initState();
    _wordScheduler = WordScheduler();
    _parameters = fsrs.Parameters();
    _initScheduler();
  }

  Future<void> _initScheduler() async {
    // No need to setState for isLoading = true here, it's the initial state.
    await _wordScheduler.init();
    // Load the first question. _loadNextQuestion handles the loading state internally.
    await _loadNextQuestion();
    // If mounted check is good practice in async initState methods,
    // although less critical if _loadNextQuestion handles its own state updates.
    if (!mounted) return;
    // The loading state is set to false inside _loadNextQuestion
  }

  Future<void> _loadNextQuestion() async {
    // Set state to indicate loading and clear previous question data
    setState(() {
      _isLoading = true;
      _currentQuestion = null;
      _feedbackMessage = '';
      _answered = false;
    });

    fsrs.Question? question;
    try {
      question = await _wordScheduler.getNextQuestion();
    } catch (e) {
      print("Error loading next question: $e");
      if (!mounted) return;
      setState(() {
        _feedbackMessage = 'Error loading question. Please try again.';
        _isLoading = false;
      });
      return;
    }

    // Check if a question was retrieved *before* accessing its properties
    if (question == null) {
      if (!mounted) return;
      // Handle the case where there are no more questions
      setState(() {
        _feedbackMessage = 'No more questions for now!';
        _currentQuestion = null; // Ensure it's null
        _isLoading = false;
      });
      return; // Exit the function
    }

    print("Current Question Word: ${question.word}"); // Safe to access now

    if (!mounted) return;
    // Update state with the new question and set loading to false
    setState(() {
      _currentQuestion = question;
      _isLoading = false;
    });
  }

  Future<void> _handleAnswer(int selectedAnswerIndex) async {
    if (_answered || _currentQuestion == null) return; // Ensure question exists

    final bool isCorrect =
        selectedAnswerIndex == _currentQuestion!.correctAnswerIndex;
    final fsrs.Rating rating = isCorrect ? fsrs.Rating.good : fsrs.Rating.again;

    // Update UI immediately to show feedback and selected state
    setState(() {
      _answered = true;
      _feedbackMessage =
          isCorrect
              ? 'Correct!'
              : 'Incorrect. The correct answer was: ${_currentQuestion!.choices[_currentQuestion!.correctAnswerIndex]}';
    });

    // Process the answer asynchronously
    await _processAnswer(rating);
  }

  Future<void> _processAnswer(fsrs.Rating rating) async {
    if (_currentQuestion == null) {
      print("Error: Tried to process answer but _currentQuestion is null.");
      return;
    }
    String wordId = _currentQuestion!.wordId;
    print("Sending rating for word $wordId: $rating");
    try {
      await _wordScheduler.updateCard(wordId, rating);
      print("Card updated successfully for word $wordId");
    } catch (e) {
      print("Error updating card for word $wordId: $e");
      if (!mounted) return;
      // Optionally show an error message to the user via feedback
      setState(() {
        _feedbackMessage += '\n(Error saving progress)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Show loading indicator
                  : Column(
                    // Use Column for layout
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Display Question and Choices ---
                      if (_currentQuestion != null) ...[
                        ClickableText(
                          text: _currentQuestion!.question,
                          style: const TextStyle(
                            fontSize: 20,
                          ), // Enhanced style
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ..._currentQuestion!.choices.asMap().entries.map((
                          entry,
                        ) {
                          final int index = entry.key;
                          final String choice = entry.value;
                          bool isCorrectChoice =
                              index == _currentQuestion!.correctAnswerIndex;
                          // Determine button color *only* after answering
                          Color? buttonColor;
                          Color? textColor = Theme.of(context)
                              .elevatedButtonTheme
                              .style
                              ?.foregroundColor
                              ?.resolve({}); // Default text color
                          if (_answered) {
                            if (isCorrectChoice) {
                              buttonColor =
                                  Colors.green.shade400; // Correct answer color
                              textColor = Colors.white;
                            } else if (index == /* user's selected index (if needed) */
                                -1 /* Replace -1 with actual selected index if you store it */ ) {
                              // We don't store selected index in this version, but could if needed for styling
                              buttonColor =
                                  Colors
                                      .red
                                      .shade400; // Incorrect selected answer color
                              textColor = Colors.white;
                            } else {
                              // Other incorrect options - keep default or grey out slightly
                              buttonColor = Colors.grey.shade300;
                              textColor = Colors.grey.shade700;
                            }
                          }

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            // Single ElevatedButton for each choice
                            child: ElevatedButton(
                              // If answered, show dictionary; otherwise, handle answer.
                              onPressed:
                                  _answered
                                      ? () =>
                                          showDictionaryPopup(context, choice)
                                      : () => _handleAnswer(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    buttonColor, // Apply color logic
                                foregroundColor:
                                    textColor, // Apply text color logic

                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ), // Button padding
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                ), // Text style
                              ).copyWith(
                                // Ensure elevation looks right when disabled
                                elevation: MaterialStateProperty.resolveWith<
                                  double
                                >((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return 0; // No shadow when disabled
                                  }
                                  return 2; // Default elevation
                                }),
                              ),
                              child: Text(choice),
                            ),
                          );
                        }), // Needed for spreading list map results
                        const SizedBox(height: 20),

                        // --- Display Feedback and Next Button ---
                        if (_answered) ...[
                          Text(
                            _feedbackMessage,
                            style: TextStyle(
                              fontSize: 18, // Slightly larger feedback
                              fontWeight: FontWeight.bold,
                              color:
                                  _feedbackMessage.startsWith('Correct')
                                      ? Colors.green
                                      : Colors.red, // Color feedback text
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: _loadNextQuestion, // Load next on press
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('Next Question'),
                          ),
                        ],
                      ]
                      // --- Display Message When No Question Loaded ---
                      else if (_feedbackMessage.isNotEmpty) ...[
                        // Handle "No more questions" or errors
                        Expanded(
                          // Use Expanded to center vertically in the Column
                          child: Center(
                            child: Text(
                              _feedbackMessage,
                              style: const TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Fallback case - should ideally not be reached if logic is sound
                        const Expanded(
                          child: Center(
                            child: Text("Preparing practice session..."),
                          ),
                        ),
                      ],
                    ],
                  ),
        ),
      ),
    );
  }
}

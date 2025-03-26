import 'package:acevocab/features/common/ui/clickable_text.dart';
import 'package:acevocab/fsrs/models.dart' as fsrs;
import 'package:acevocab/fsrs/word_scheduler.dart';
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
  late fsrs.Parameters _parameters;
  bool _isLoading = true; // Add a loading indicator flag

  @override
  void initState() {
    super.initState();
    _wordScheduler = WordScheduler();
    _parameters = fsrs.Parameters();
    _initScheduler();
  }

  Future<void> _initScheduler() async {
    await _wordScheduler.init();
    await _loadNextQuestion();
    setState(() {
      _isLoading =
          false; // Set loading to false after initialization and loading
    });
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _currentQuestion = null;
      _feedbackMessage = '';
      _answered = false;
      // Reset _currentCard
      //_isLoading = true;  // Optional: Show loading indicator between questions.
    });

    fsrs.Question? question;

    question = await _wordScheduler.getNextQuestion();

    print("Current Question: " + question!.word);

    if (question == null) {
      // Handle the case where there are no more questions
      setState(() {
        _feedbackMessage = 'No more questions for now!';
        _isLoading = false; //Optional
        return;
      });
    }

    _isLoading = false;

    setState(() {
      _currentQuestion = question;
      // _isLoading = false; // Optional.
    });
  }

  Future<void> _handleAnswer(int selectedAnswerIndex) async {
    if (_answered) return;

    setState(() {
      _answered = true;
    });

    final isCorrect =
        selectedAnswerIndex == _currentQuestion!.correctAnswerIndex;

    fsrs.Rating rating; // Store rating in variable to use later

    if (!isCorrect) {
      setState(() {
        _feedbackMessage =
            'Incorrect. The correct answer was '
            '${_currentQuestion!.choices[_currentQuestion!.correctAnswerIndex]}';
      });
      rating = fsrs.Rating.again;
    } else {
      setState(() {
        _feedbackMessage = 'Correct!';
      });
      rating = fsrs.Rating.good;
    }

    // Process the answer *before* introducing the delay.
    await _processAnswer(rating);

    // Delay *after* processing the answer.
    await Future.delayed(Duration(seconds: 1));

    await _loadNextQuestion();
  }

  Future<void> _processAnswer(fsrs.Rating rating) async {
    // Now _currentCard should have a value.

    String wordId = _currentQuestion!.wordId;
    print("Sending rating for word $wordId: $rating");
    await _wordScheduler.updateCard(wordId, rating);
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
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                    // Use a ternary operator for loading
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentQuestion != null) ...[
                        ClickableText(
                          // Replace the Text widget
                          text: _currentQuestion!.question,
                          style: TextStyle(fontSize: 20),
                          textAlign:
                              TextAlign.center, // Example of using textAlign
                          // maxLines: 3, //example of using maxLines
                        ),
                        SizedBox(height: 20),
                        ..._currentQuestion!.choices.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed: () => _handleAnswer(entry.key),
                              child: Text(entry.value),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _answered
                                        ? (entry.key ==
                                                _currentQuestion!
                                                    .correctAnswerIndex
                                            ? Colors.green
                                            : Colors.red)
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Show feedback message if no question
                        Text(_feedbackMessage),
                      ],
                      SizedBox(height: 20),
                      Text(_feedbackMessage), // Show Feedback
                    ],
                  ),
        ),
      ),
    );
  }
}

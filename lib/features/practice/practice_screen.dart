import 'dart:math';

import 'package:acevocab/fsrs/models.dart' as fsrs; // Import with prefix
import 'package:acevocab/fsrs/word_scheduler.dart';
import 'package:flutter/material.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState(); // Correct return type
}

class _PracticeScreenState extends State<PracticeScreen> {
  late WordScheduler _wordScheduler;
  fsrs.Question? _currentQuestion; // Use prefixed type
  String _feedbackMessage = '';
  bool _answered = false;
  fsrs.Card? _currentCard; // Use prefixed type
  late fsrs.Parameters _parameters;

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
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _currentQuestion = null;
      _feedbackMessage = '';
      _answered = false;
    });
    fsrs.Question? question;
    try {
      print("Fetching Question");
      question = await _wordScheduler.getNextQuestion();
      print(question!.word);
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Error: $e';
      });
    }
    setState(() {
      _currentQuestion = question;
      _feedbackMessage = '';
      _answered = false;
    });
  }

  Future<void> _handleAnswer(int selectedAnswerIndex) async {
    if (_answered) return;

    setState(() {
      _answered = true;
    });

    final isCorrect =
        selectedAnswerIndex == _currentQuestion!.correctAnswerIndex;
    if (!isCorrect) {
      setState(() {
        _feedbackMessage =
            'Incorrect. The correct answer was '
            '${_currentQuestion!.choices[_currentQuestion!.correctAnswerIndex]}';
      });
    } else {
      setState(() {
        _feedbackMessage = 'Correct!';
      });
    }

    await Future.delayed(Duration(seconds: 1));
    print("Loading Next question");
    await _loadNextQuestion();
  }

  Future<void> _processAnswer(fsrs.Rating rating) async {
    if (_currentCard == null) {
      throw Exception('current card is null');
    }
    fsrs.Card card = _currentCard!;
    final now = DateTime.now();

    final scheduling = fsrs.SchedulingCards(card);
    scheduling.updateState(card.state);

    final retrievability = card.getRetrievability(now);
    final w = _parameters.w;
    late double difficulty;
    late double stability;
    late double interval;

    if (retrievability == null) {
      // New card.
      final defaultDifficulty = w[4];
      final initialFactor = w[5];
      final firstEase = w[6];
      final firstHard = w[7];
      difficulty = defaultDifficulty;
      stability = switch (rating) {
        fsrs.Rating.again => initialFactor,
        fsrs.Rating.hard => firstHard,
        fsrs.Rating.good => firstEase,
        fsrs.Rating.easy => firstEase * 2,
      };
    } else {
      // ... (rest of your existing logic, using fsrs.Rating where needed) ...
      final lapses = card.lapses;
      final previousDifficulty = card.difficulty;
      final previousStability = card.stability;

      // Diff related
      final diffDecrease = w[8];
      final diffHard = w[9];
      final diffEasy = w[10];

      // Stability related
      final easyBonus = w[11];
      final hardInterval = w[12];
      final hardPenalty = w[13];
      final learnAgain = w[14];
      final relearnAgain = w[15];
      final relearnHard = w[16];
      final requestRetention = w[17];
      final maximumInterval = w[18];

      difficulty =
          previousDifficulty +
          (rating.index + 1 - 2) *
              (diffDecrease +
                  (previousDifficulty - 1) * (diffHard - diffEasy) / (10 - 1));
      difficulty = min(10, max(1, difficulty));

      stability = switch (rating) {
        fsrs.Rating.again =>
          card.state == fsrs.State.learning ? learnAgain : relearnAgain,
        fsrs.Rating.hard =>
          previousStability *
              (1 - hardInterval * (1 - retrievability)) *
              hardPenalty,
        fsrs.Rating.good =>
          previousStability *
              (1 +
                  ((exp(
                            w[2] *
                                (11 - difficulty) *
                                pow(previousStability, w[3]),
                          )) -
                          1) *
                      (1 - retrievability)),
        fsrs.Rating.easy =>
          previousStability *
              (1 +
                  ((exp(
                            w[2] *
                                (11 - difficulty) *
                                pow(previousStability, w[3]),
                          )) -
                          1) *
                      (1 - retrievability) *
                      easyBonus),
      };
    }
    final initialInterval = w[0];
    final intervalModifier = w[1];
    interval = switch (rating) {
      fsrs.Rating.again => initialInterval,
      fsrs.Rating.hard || fsrs.Rating.good || fsrs.Rating.easy =>
        stability *
            intervalModifier *
            exp(w[2] * (11 - difficulty) * pow(stability, w[3])),
    };

    final info = scheduling.recordLog(card, now)[rating]!;
    final updatedCard = info.card.copyWith(
      stability: stability,
      difficulty: difficulty,
      lastReview: now,
      elapsedDays: now.difference(card.lastReview).inDays,
      reps: card.reps + 1,
      lapses:
          (card.state == fsrs.State.review &&
                  info.card.state != fsrs.State.review)
              ? card.lapses + 1
              : card.lapses,
      state: info.card.state,
      due: now.add(Duration(days: interval.ceil())),
    );
    updatedCard.reviewLogs.add(info.reviewLog);

    await _wordScheduler.updateCard(updatedCard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentQuestion != null) ...[
              Text(_currentQuestion!.question, style: TextStyle(fontSize: 20)),
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
                                      _currentQuestion!.correctAnswerIndex
                                  ? Colors.green
                                  : Colors.red)
                              : null,
                    ),
                  ),
                ),
              ),
            ] else if (_feedbackMessage.isNotEmpty) ...[
              Text(_feedbackMessage),
            ] else ...[
              CircularProgressIndicator(),
            ],
            SizedBox(height: 20),
            Text(_feedbackMessage),
          ],
        ),
      ),
    );
  }
}

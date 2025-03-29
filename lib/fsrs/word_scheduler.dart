import 'package:acevocab/data/local_sqlite_helper.dart';
import 'package:acevocab/fsrs/fsrs_storage.dart';
import 'package:acevocab/fsrs/models.dart';
import 'package:collection/collection.dart'; // For PriorityQueue
import 'dart:math';
import 'package:acevocab/fsrs/fsrs_base.dart';

class WordScheduler {
  // Singleton instance
  static WordScheduler? _instance;

  // Private constructor
  WordScheduler._internal();

  // Public factory method to get the instance
  static Future<WordScheduler> getInstance() async {
    if (_instance == null) {
      _instance = WordScheduler._internal();
      await _instance!._init(); // Call the private init method
    }
    return _instance!;
  }

  late FSRSStorage _storage; // Made non-final for init
  late LocalSqliteHelper _localSqliteHelper; // Made non-final for init
  final PriorityQueue<Card> _queue = PriorityQueue<Card>(
    (a, b) => a.due.compareTo(b.due),
  );
  List<Card> _cards = []; // In-memory list of cards
  double reviewToExploreRatio = 0.7;
  final FSRS _fsrs = FSRS();

  Future<void> _init() async {
    _storage = await FSRSStorage.getInstance();
    _localSqliteHelper = LocalSqliteHelper.instance;
    _cards = await _storage.getAllCards();
    _sortQueue();
  }

  Future<void> updateCard(String wordId, Rating rating) async {
    var card = _cards.firstWhereOrNull((c) => c.wordId == wordId);
    final now = DateTime.now();
    late final Card newCard;
    late final ReviewLog newReviewLog;

    if (card == null) {
      // Card not found, create a new one.
      Question? question = await _localSqliteHelper.getQuestionData(
        int.parse(wordId),
      );
      if (question == null) {
        throw Exception('Word not found in database: $wordId');
      }
      card = Card(wordId: wordId, due: now, lastReview: now);
      Map<Rating, SchedulingInfo> info = _fsrs.repeat(card, now);
      newCard = info[rating]!.card;
      newReviewLog = info[rating]!.reviewLog;
      final newId = await _storage.createCard(newCard);
      print(newReviewLog);
    } else {
      // Card found, update it.

      if (card.id == null) {
        throw Exception('Card ID cannot be null when updating.');
      }
      Map<Rating, SchedulingInfo> info = _fsrs.repeat(card, now);
      newCard = info[rating]!.card;
      newReviewLog = info[rating]!.reviewLog;
      // Delete from ObjectBox and in-memory list
      await _storage.deleteCard(card.id!);
      _cards.removeWhere((c) => c.id == card!.id);

      // Add the updated card (ObjectBox will assign a new ID)
      final newId = await _storage.createCard(newCard);
    }

    final storedCard = await _storage.getCardByWordId(wordId);
    if (storedCard == null) {
      throw Exception('new card created is null');
    }
    storedCard.reviewLogs.add(newReviewLog);
    print(storedCard);
    await _storage.updateCard(storedCard);

    // newCard.reviewLogs.add(newReviewLog);
    //

    _cards = await _storage.getAllCards();
    _sortQueue();
    print(_queue);
  }

  Future<Question?> getNextQuestion() async {
    final dueCards = _getDueCards();
    int wordId;

    if (dueCards.isEmpty) {
      // Explore (no cards to review)
      wordId = await _exploreWord();
      print(wordId);
    } else {
      final random = Random();
      if (random.nextDouble() < reviewToExploreRatio) {
        // Review
        wordId = int.parse(_queue.first.wordId);
      } else {
        // Explore
        wordId = await _exploreWord();
      }
    }

    Question? question = await _localSqliteHelper.getQuestionData(wordId);
    return question;
  }

  /// Clears all card data from storage and internal memory.

  Future<void> clearAllData() async {
    await _storage.clearAllCards(); // Clear from database
    _queue.clear(); // Clear in-memory queue
    _cards.clear(); // Clear in-memory card list
    print('All card data cleared from storage and scheduler memory.');
  }

  Future<int> _exploreWord() async {
    final preset = await _localSqliteHelper.getDefaultPreset();
    if (preset == null) {
      throw Exception('No default preset found.');
    }

    final existingWordIds = _cards.map((card) => card.wordId).toSet();
    final availableWordIds = preset.wordIds.where(
      (id) => !existingWordIds.contains(id.toString()),
    );

    if (availableWordIds.isEmpty) {
      throw Exception(
        'No new words to explore (all words in preset are already in cards).',
      );
    }

    final random = Random();
    final wordId = availableWordIds.elementAt(
      random.nextInt(availableWordIds.length),
    );

    return wordId;
  }

  List<Card> _getDueCards() {
    final now = DateTime.now();
    return _cards.where((card) => card.due.isBefore(now)).toList();
  }

  void _sortQueue() {
    _queue.clear();
    _queue.addAll(_cards);
  }
}

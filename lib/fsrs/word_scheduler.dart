import 'package:acevocab/data/local_sqlite_helper.dart';
import 'package:acevocab/fsrs/fsrs_storage.dart';
import 'package:acevocab/fsrs/models.dart';
import 'package:collection/collection.dart'; // For PriorityQueue
import 'dart:math';

class WordScheduler {
  late final FSRSStorage _storage;
  late final LocalSqliteHelper _localSqliteHelper;
  final PriorityQueue<Card> _queue = PriorityQueue<Card>(
    (a, b) => a.due.compareTo(b.due),
  );
  List<Card> _cards = []; // In-memory list of cards
  double reviewToExploreRatio = 0.7;

  Future<void> init() async {
    _storage = await FSRSStorage.getInstance();
    _localSqliteHelper = LocalSqliteHelper.instance;
    _cards = await _storage.getAllCards();
    _sortQueue();
  }

  Future<void> updateCard(Card card) async {
    if (card.id == null) {
      throw Exception('Card ID cannot be null when updating.');
    }

    // Delete from ObjectBox and in-memory list
    await _storage.deleteCard(card.id!);
    _cards.removeWhere((c) => c.id == card.id);

    // Add the updated card (ObjectBox will assign a new ID)
    final newId = await _storage.createCard(card);
    final newCard = await _storage.getCardById(newId);
    if (newCard == null) {
      throw Exception('new card created is null');
    }
    _cards.add(newCard);
    _sortQueue();
  }

  Future<Question?> getNextQuestion() async {
    final dueCards = _getDueCards();
    int wordId;

    if (dueCards.isEmpty) {
      // Explore (no cards to review)
      wordId = await _exploreWord();
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

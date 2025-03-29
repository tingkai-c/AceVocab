import 'package:acevocab/data/objectbox_helper.dart';

import 'models.dart'; // Import your model classes (Card, StoredCard, ReviewLog, etc.)
import '../objectbox.g.dart'; // Import the generated ObjectBox code

class FSRSStorage {
  late final Store _store;
  late final Box<StoredCard> _cardBox;
  late final Box<ReviewLog> _reviewLogBox;
  late final ObjectBoxHelper _objectBoxHelper;

  // Singleton pattern (optional, but good practice for database access)
  static FSRSStorage? _instance;

  FSRSStorage._internal() {
    _objectBoxHelper = ObjectBoxHelper.instance;
    _cardBox = _objectBoxHelper.cardBox;
    _reviewLogBox = _objectBoxHelper.reviewLogBox;
  }

  static Future<FSRSStorage> getInstance() async {
    if (_instance == null) {
      ObjectBoxHelper.init();
      _instance = FSRSStorage._internal();
    }
    return _instance!;
  }

  // Close the store (call this when your app is closing)
  void close() {
    _store.close();
  }

  // --- Card Operations ---

  // Create a new card.  Throws an exception if a card with the same wordId exists.
  Future<int> createCard(Card card) async {
    if (await getCardByWordId(card.wordId) != null) {
      throw Exception('A card with wordId "${card.wordId}" already exists.');
    }
    StoredCard storedCard = cardToStoredCard(card);
    return _cardBox.put(storedCard); // Returns the new card's ID
  }

  // Get a card by its ObjectBox ID.
  Future<Card?> getCardById(int id) async {
    StoredCard? storedCard = _cardBox.get(id);
    return storedCard != null ? storedCardToCard(storedCard) : null;
  }

  // Get a card by its wordId.  Returns null if not found.
  Future<Card?> getCardByWordId(String wordId) async {
    Query<StoredCard> query =
        _cardBox.query(StoredCard_.wordId.equals(wordId)).build();
    StoredCard? storedCard = query.findFirst(); // Use findFirst for one-to-one
    query.close();
    return storedCard != null ? storedCardToCard(storedCard) : null;
  }

  // Get all cards.
  Future<List<Card>> getAllCards() async {
    List<StoredCard> storedCards = _cardBox.getAll();
    return storedCards.map(storedCardToCard).toList();
  }

  // Update an existing card.
  Future<void> updateCard(Card card) async {
    // Ensure the card exists
    if (card.id == null) {
      throw Exception('Cannot update a card without an ID.');
    }

    // Fetch the existing StoredCard
    StoredCard? existingStoredCard = _cardBox.get(card.id!);

    if (existingStoredCard == null) {
      throw Exception('Card with ID ${card.id} not found.');
    }

    // Check for wordId conflicts (excluding the current card)
    Query<StoredCard> conflictQuery =
        _cardBox
            .query(
              StoredCard_.wordId
                  .equals(card.wordId)
                  .and(StoredCard_.id.notEquals(card.id!)),
            ) // Exclude current card
            .build();

    if (conflictQuery.count() > 0) {
      conflictQuery.close();
      throw Exception(
        'Another card with wordId "${card.wordId}" already exists.',
      );
    }
    conflictQuery.close();

    // Update the properties of the existing StoredCard

    existingStoredCard.due = card.due;
    existingStoredCard.lastReview = card.lastReview;
    existingStoredCard.stability = card.stability;
    existingStoredCard.difficulty = card.difficulty;
    existingStoredCard.elapsedDays = card.elapsedDays;
    existingStoredCard.scheduledDays = card.scheduledDays;
    existingStoredCard.reps = card.reps;
    existingStoredCard.lapses = card.lapses;
    existingStoredCard.stateEnum = card.state;

    // Update the review logs relationship
    // ObjectBox handles adding new ReviewLog entities found in the list
    // and updating the relationship when the StoredCard is put.
    existingStoredCard.reviewLogs.clear(); // Clear existing relations first
    existingStoredCard.reviewLogs.addAll(
      card.reviewLogs,
    ); // Add all logs from the input card

    _cardBox.put(existingStoredCard); // Put the updated existing StoredCard
  }

  // Delete a card by its ObjectBox ID.
  Future<void> deleteCard(int id) async {
    _cardBox.remove(id);
  }

  // Delete a card by its word ID.
  Future<void> deleteCardByWordId(String wordId) async {
    Query<StoredCard> query =
        _cardBox.query(StoredCard_.wordId.equals(wordId)).build();
    StoredCard? storedCard = query.findFirst();
    query.close();
    if (storedCard != null) {
      _cardBox.remove(storedCard.id);
    }
  }

  // Clear all cards from the database.
  Future<void> clearAllCards() async {
    // removeAll returns the count of removed objects
    int removedCount = await _cardBox.removeAll();
    int removedReviewLogCount = await _reviewLogBox.removeAll();
    print(
      'Removed $removedCount cards  and $removedReviewLogCount review logs from the database.',
    );
    // Note: Depending on ObjectBox setup, related ReviewLogs might be removed
    // automatically. If not, you might need to clear them explicitly:
    // await _reviewLogBox.removeAll();
  }

  // --- ReviewLog Operations (Example) ---

  // Add a review log to a card.
  Future<int> addReviewLog(int cardId, ReviewLog reviewLog) async {
    StoredCard? storedCard = _cardBox.get(cardId);
    if (storedCard == null) {
      throw Exception('Card with ID $cardId not found.');
    }

    storedCard.reviewLogs.add(reviewLog);
    _cardBox.put(storedCard); // Update the card to save the relationship
    return reviewLog.id; // Assuming ReviewLog's id is auto-generated
  }

  // --- Conversion Functions (Moved here for better organization) ---

  // Convert a StoredCard to a Card (for UI)
  Card storedCardToCard(StoredCard storedCard) {
    return Card(
      id: storedCard.id,
      wordId: storedCard.wordId, // Add this
      due: storedCard.due,
      lastReview: storedCard.lastReview,
      stability: storedCard.stability,
      difficulty: storedCard.difficulty,
      elapsedDays: storedCard.elapsedDays,
      scheduledDays: storedCard.scheduledDays,
      reps: storedCard.reps,
      lapses: storedCard.lapses,
      state: storedCard.stateEnum,
      reviewLogs: storedCard.reviewLogs.toList(), // Convert ToMany to List
    );
  }

  // Convert a Card to a StoredCard (for database storage)
  StoredCard cardToStoredCard(Card card) {
    return StoredCard(
      wordId: card.wordId, // Add this
      due: card.due,
      lastReview: card.lastReview,
      stability: card.stability,
      difficulty: card.difficulty,
      elapsedDays: card.elapsedDays,
      scheduledDays: card.scheduledDays,
      reps: card.reps,
      lapses: card.lapses,
      stateEnum: card.state,
    );
  }
}

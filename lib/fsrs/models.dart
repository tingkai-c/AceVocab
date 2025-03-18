import 'dart:core';
import 'dart:math';
import 'package:objectbox/objectbox.dart';

// Enums (remain the same)
enum State {
  newState(val: 0),
  learning(val: 1),
  review(val: 2),
  relearning(val: 3);

  const State({required this.val});
  final int val;
}

enum Rating {
  again(val: 1),
  hard(val: 2),
  good(val: 3),
  easy(val: 4);

  const Rating({required this.val});
  final int val;
}

// --- ReviewLog Entity ---
@Entity()
class ReviewLog {
  @Id()
  int id = 0;

  @Property(type: PropertyType.int)
  int rating;
  int scheduledDays;
  int elapsedDays;
  DateTime? review;

  @Property(type: PropertyType.int)
  int state; // Store the integer value

  // Constructor with optional named parameters and defaults
  ReviewLog({
    Rating ratingEnum = Rating.again,
    this.scheduledDays = 0,
    this.elapsedDays = 0,
    this.review,
    State stateEnum = State.newState, //Now a default value
  }) : state = stateEnum.val,
       rating = ratingEnum.val;

  // Helper methods for Rating enum (getter and setter)
  Rating get ratingEnum => Rating.values.firstWhere((e) => e.val == rating);
  set ratingEnum(Rating value) => rating = value.val;

  // Helper methods for State enum (getter and setter)
  State get stateEnum => State.values[state]; // Get enum from int
  set stateEnum(State value) => state = value.val; // Set int from enum

  @override
  String toString() {
    return 'ReviewLog{id: $id, rating: $ratingEnum, scheduledDays: $scheduledDays, elapsedDays: $elapsedDays, review: $review, state: $stateEnum}';
  }
}

@Entity()
class StoredCard {
  @Id()
  int id = 0;

  String wordId;
  DateTime due;
  DateTime lastReview;
  double stability;
  double difficulty;
  int elapsedDays;
  int scheduledDays;
  int reps;
  int lapses;

  @Property(type: PropertyType.int)
  int state; // Store the integer value of the State enum

  final reviewLogs = ToMany<ReviewLog>();

  StoredCard({
    required this.wordId,
    required this.due,
    required this.lastReview,
    this.stability = 0,
    this.difficulty = 0,
    this.elapsedDays = 0,
    this.scheduledDays = 0,
    this.reps = 0,
    this.lapses = 0,
    State stateEnum = State.newState, // Use the enum here, not the int
  }) : state = stateEnum.val; // Initialize 'state' with the enum's int value

  // Getter: Converts the int 'state' to the State enum
  State get stateEnum => State.values[state];

  // Setter: Converts a State enum to its int representation
  set stateEnum(State value) => state = value.val;

  @override
  String toString() {
    return 'StoredCard{id: $id, wordId: $wordId, due: $due, lastReview: $lastReview, stability: $stability, difficulty: $difficulty, elapsedDays: $elapsedDays, scheduledDays: $scheduledDays, reps: $reps, lapses: $lapses, state: $stateEnum, reviewLogs: ${reviewLogs.length}}';
  }
}

// --- Card (UI Logic and Calculations) ---
// This class is *not* an ObjectBox entity.  It's for UI and business logic.
class Card {
  final int? id; // Now nullable, as new cards won't have an ID yet
  final String wordId;
  DateTime due;
  DateTime lastReview;
  double stability;
  double difficulty;
  int elapsedDays;
  int scheduledDays;
  int reps;
  int lapses;
  State state;
  List<ReviewLog> reviewLogs; // Use the ReviewLog entity directly

  Card({
    this.id, // Nullable ID
    required this.wordId,
    required this.due,
    required this.lastReview,
    this.stability = 0,
    this.difficulty = 0,
    this.elapsedDays = 0,
    this.scheduledDays = 0,
    this.reps = 0,
    this.lapses = 0,
    this.state = State.newState,
    this.reviewLogs = const [], // Default to an empty list
  });

  // copyWith (for immutability in UI logic)
  Card copyWith({
    int? id,
    String? wordId,
    DateTime? due,
    DateTime? lastReview,
    double? stability,
    double? difficulty,
    int? elapsedDays,
    int? scheduledDays,
    int? reps,
    int? lapses,
    State? state,
    List<ReviewLog>? reviewLogs,
  }) {
    return Card(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      state: state ?? this.state,
      reviewLogs: reviewLogs ?? this.reviewLogs,
    );
  }

  double? getRetrievability(DateTime now) {
    const decay = -0.5;
    final factor = pow(0.9, 1 / decay) - 1;

    if (state == State.review) {
      final elapsedDays =
          (now.difference(lastReview).inDays).clamp(0, double.infinity).toInt();
      return pow(1 + factor * elapsedDays / stability, decay).toDouble();
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return 'Card{id: $id, wordId: $wordId, due: $due, lastReview: $lastReview, stability: $stability, difficulty: $difficulty, elapsedDays: $elapsedDays, scheduledDays: $scheduledDays, reps: $reps, lapses: $lapses, state: $state, reviewLogs: $reviewLogs}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          wordId == other.wordId &&
          due == other.due &&
          lastReview == other.lastReview &&
          stability == other.stability &&
          difficulty == other.difficulty &&
          elapsedDays == other.elapsedDays &&
          scheduledDays == other.scheduledDays &&
          reps == other.reps &&
          lapses == other.lapses &&
          state == other.state &&
          reviewLogs == other.reviewLogs;

  @override
  int get hashCode =>
      id.hashCode ^
      wordId.hashCode ^
      due.hashCode ^
      lastReview.hashCode ^
      stability.hashCode ^
      difficulty.hashCode ^
      elapsedDays.hashCode ^
      scheduledDays.hashCode ^
      reps.hashCode ^
      lapses.hashCode ^
      state.hashCode ^
      reviewLogs.hashCode;
}

/// Store card and review log info
class SchedulingInfo {
  late Card card;
  late ReviewLog reviewLog;

  SchedulingInfo(this.card, this.reviewLog);
}

/// Calculate next review
class SchedulingCards {
  late Card again;
  late Card hard;
  late Card good;
  late Card easy;

  SchedulingCards(Card card) {
    again = card.copyWith();
    hard = card.copyWith();
    good = card.copyWith();
    easy = card.copyWith();
  }

  void updateState(State state) {
    switch (state) {
      case State.newState:
        again.state = State.learning;
        hard.state = State.learning;
        good.state = State.learning;
        easy.state = State.review;
      case State.learning:
      case State.relearning:
        again.state = state;
        hard.state = state;
        good.state = State.review;
        easy.state = State.review;
      case State.review:
        again.state = State.relearning;
        hard.state = State.review;
        good.state = State.review;
        easy.state = State.review;
        again.lapses++;
    }
  }

  void schedule(
    DateTime now,
    double hardInterval,
    double goodInterval,
    double easyInterval,
  ) {
    again.scheduledDays = 0;
    hard.scheduledDays = hardInterval.toInt();
    good.scheduledDays = goodInterval.toInt();
    easy.scheduledDays = easyInterval.toInt();
    again.due = now.add(Duration(minutes: 5));
    hard.due =
        (hardInterval > 0)
            ? now.add(Duration(days: hardInterval.toInt()))
            : now.add(Duration(minutes: 10));
    good.due = now.add(Duration(days: goodInterval.toInt()));
    easy.due = now.add(Duration(days: easyInterval.toInt()));
  }

  Map<Rating, SchedulingInfo> recordLog(Card card, DateTime now) {
    return {
      Rating.again: SchedulingInfo(
        again,
        ReviewLog(
          ratingEnum: Rating.again,
          scheduledDays: again.scheduledDays,
          elapsedDays: card.elapsedDays,
          review: now,
          stateEnum: card.state,
        ),
      ),
      Rating.hard: SchedulingInfo(
        hard,
        ReviewLog(
          ratingEnum: Rating.hard,
          scheduledDays: hard.scheduledDays,
          elapsedDays: card.elapsedDays,
          review: now,
          stateEnum: card.state,
        ),
      ),
      Rating.good: SchedulingInfo(
        good,
        ReviewLog(
          ratingEnum: Rating.good,
          scheduledDays: good.scheduledDays,
          elapsedDays: card.elapsedDays,
          review: now,
          stateEnum: card.state,
        ),
      ),
      Rating.easy: SchedulingInfo(
        easy,
        ReviewLog(
          ratingEnum: Rating.easy,
          scheduledDays: easy.scheduledDays,
          elapsedDays: card.elapsedDays,
          review: now,
          stateEnum: card.state,
        ),
      ),
    };
  }
}

class Parameters {
  double requestRetention = 0.9;
  int maximumInterval = 36500;
  List<double> w = [
    0.4,
    0.6,
    2.4,
    5.8,
    4.93,
    0.94,
    0.86,
    0.01,
    1.49,
    0.14,
    0.94,
    2.18,
    0.05,
    0.34,
    1.26,
    0.29,
    2.61,
  ];
}

class VocabPreset {
  String name = "";
  String description = "";
  List<int> wordIds = [];

  VocabPreset({
    required this.name,
    required this.description,
    required this.wordIds,
  });
}

class Question {
  String question;
  String wordId;
  List<String> choices;
  int correctAnswerIndex;
  String word;

  Question({
    required this.question,
    required this.wordId,
    required this.choices,
    required this.correctAnswerIndex,
    required this.word,
  });
}

import 'dart:io';
import 'dart:math'; // Import for Random
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:acevocab/fsrs/models.dart';
import 'dart:convert';

class LocalSqliteHelper {
  static final LocalSqliteHelper instance =
      LocalSqliteHelper._privateConstructor();
  LocalSqliteHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(
      documentsDirectory.path,
      'vocabulary.db',
    ); // Consider renaming your database if you want

    bool databaseExists = await databaseFactory.databaseExists(path);

    if (true) {
      // Corrected the condition to check if it DOESN'T exist
      try {
        ByteData data = await rootBundle.load(
          join('assets', 'db', 'vocabulary.db'),
        ); // Your database file path
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
        print("Database copied from assets");
      } catch (e) {
        print("Error copying database: $e");
        throw e;
      }
    } else {
      print("Database already exists, skipping copy.");
    }

    return await openDatabase(path, readOnly: true);
  }

  // Get all records (for demonstration or other uses)
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    Database db = await instance.database;
    return await db.query('words'); // Your table name
  }

  // Get word from word_id
  Future<String?> getWordFromId(int wordId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'words',
      columns: ['word'], // Only select the 'word' column
      where: 'id = ?',
      whereArgs: [wordId],
    );

    if (result.isNotEmpty) {
      return result.first['word'] as String; // Safely cast to String
    } else {
      return null; // Word ID not found
    }
  }

  // Get word_id from word
  Future<int?> getWordIdFromWord(String word) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'words',
      columns: ['id'], // Only select the 'word_id' column
      where: 'word = ?',
      whereArgs: [word],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int; // Safely cast to int
    } else {
      return null; // Word not found
    }
  }

  // New function to get question data
  Future<Map<String, dynamic>?> getQuestionData(int wordId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'questions',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    if (results.isEmpty) {
      return null; // No question found for this word_id
    }

    Map<String, dynamic> questionData =
        results.first; // Get the first (and likely only) result

    // Get the word itself using the existing function
    String? word = await getWordFromId(wordId);
    if (word == null) {
      return null; //should not happen, as word_id should have a word.
    }

    // Create a list of all answers
    List<String> answers = [
      questionData['correct_answer'] as String,
      questionData['wrong_answer1'] as String,
      questionData['wrong_answer2'] as String,
      questionData['wrong_answer3'] as String,
    ];

    // Shuffle the answers randomly
    final random = Random();
    List<String> shuffledAnswers = answers..shuffle(random);

    // Find the index of the correct answer in the shuffled list
    int correctAnswerIndex = shuffledAnswers.indexOf(
      questionData['correct_answer'],
    );

    // Return all the data in a Map
    return {
      'id': questionData['id'], // Question ID
      'sentence': questionData['question'], // The question sentence
      'choices': shuffledAnswers, // Randomized answer choices
      'correctAnswerIndex': correctAnswerIndex, // Index of the correct answer
      'word': word, //the word
    };
  }

  Future<VocabPreset?> getDefaultPreset() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('default_preset');

    if (result.isEmpty) {
      return null; // Table is empty
    }

    Map<String, dynamic> row = result.first; // Get the first (and only) row

    // Parse word_ids string into a List<int>
    String wordIdsString = row['word_ids'] as String;
    List<dynamic> wordIdsDynamic = jsonDecode(wordIdsString);
    List<int> wordIds =
        wordIdsDynamic.map((e) => int.parse(e.toString())).toList();

    return VocabPreset(
      name: row['name'] as String,
      description: row['description'] as String,
      wordIds: wordIds,
    );
  }
}

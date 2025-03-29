import 'dart:async'; // For Future
import 'dart:io'; // For Directory
import 'package:acevocab/data/user_data.dart'; // Adjust import path if needed
import 'package:acevocab/fsrs/models.dart'; // Adjust import path if needed
import 'package:flutter/foundation.dart'; // For kDebugMode (optional logging)
import 'package:objectbox/objectbox.dart'; // ObjectBox core
import 'package:path_provider/path_provider.dart'; // To find app's documents directory
import 'package:path/path.dart' as p; // To join paths correctly

// Import the generated file (adjust path if needed)
import '../objectbox.g.dart'; // Adjust path based on your project structure

/// Manages the ObjectBox Store and provides access to Boxes.
///
/// Follows the singleton pattern with asynchronous initialization.
/// Must be initialized by calling `await ObjectBoxHelper.init()` before accessing
/// the instance via `ObjectBoxHelper.instance`.
class ObjectBoxHelper {
  /// The singleton instance, private to prevent external instantiation.
  static ObjectBoxHelper? _instance;

  /// The underlying ObjectBox Store.
  final Store _store;

  /// Box for UserData entities.
  late final Box<UserData> _userDataBox;

  /// Box for StoredCard entities.
  late final Box<StoredCard> _cardBox;

  /// Box for ReviewLog entities.
  late final Box<ReviewLog> _reviewLogBox;

  /// Private constructor. Use `ObjectBoxHelper.init()` to create and initialize.
  ObjectBoxHelper._create(this._store) {
    // Initialize Boxes immediately after the store is available.
    _userDataBox = _store.box<UserData>();
    _cardBox = _store.box<StoredCard>();
    _reviewLogBox = _store.box<ReviewLog>();

    _log("ObjectBoxHelper created. Boxes initialized.");

    // Ensure default data exists when the instance is first created.
    _ensureDefaultUserDataExists();
  }

  /// Returns the singleton instance.
  ///
  /// Throws a [StateError] if `init()` has not been called successfully.
  static ObjectBoxHelper get instance {
    if (_instance == null) {
      throw StateError(
        'ObjectBoxHelper not initialized. Call `await ObjectBoxHelper.init()` first.',
      );
    }
    return _instance!;
  }

  /// Initializes the ObjectBox store and the singleton instance.
  ///
  /// Must be called once, typically in `main()`, before accessing the instance.
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ObjectBoxHelper.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init() async {
    // Prevent multiple initializations
    if (_instance != null) {
      _log("ObjectBoxHelper already initialized.");
      return;
    }

    _log("ObjectBoxHelper initializing...");
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      // Consider using a sub-directory for clarity, e.g., 'objectbox_db'
      final storePath = p.join(docsDir.path, "acevocab_db", "objectbox");
      _log("ObjectBox database path: $storePath");

      // Ensure the directory exists (optional, openStore might handle it)
      final dbDir = Directory(storePath);
      if (!await dbDir.exists()) {
        _log("Creating database directory.");
        await dbDir.create(recursive: true);
      }

      // Open the ObjectBox Store using the generated model definition.
      // This is where objectbox.g.dart is crucial.
      final store = await openStore(directory: storePath);
      _log("ObjectBox Store opened successfully.");

      // Create the singleton instance using the private constructor.
      _instance = ObjectBoxHelper._create(store);
      _log("ObjectBoxHelper initialization complete.");
    } catch (e, s) {
      // Catch stack trace as well for better debugging
      _log(
        "FATAL: Failed to initialize ObjectBox: $e\nStackTrace: $s",
        isError: true,
      );
      // Depending on the app, you might want to show an error UI
      // or gracefully degrade functionality instead of rethrowing.
      rethrow; // Rethrow to signal initialization failure
    }
  }

  // --- Public Accessors ---

  /// Provides direct access to the underlying ObjectBox Store.
  /// Use with caution, prefer using Box accessors.
  Store get store => _store;

  /// Provides access to the Box for UserData entities.
  Box<UserData> get userDataBox => _userDataBox;

  /// Provides access to the Box for StoredCard entities.
  Box<StoredCard> get cardBox => _cardBox;

  /// Provides access to the Box for ReviewLog entities.
  Box<ReviewLog> get reviewLogBox => _reviewLogBox;

  // --- Helper Methods (Internal) ---

  /// Ensures that a default UserData object exists if the box is empty.
  /// Called internally during initialization.
  void _ensureDefaultUserDataExists() {
    if (_userDataBox.isEmpty()) {
      _log("No UserData found, creating default.");
      final defaultUserData =
          UserData(); // Assumes default constructor is sufficient
      final id = _userDataBox.put(defaultUserData);
      _log("Default UserData created with ID: $id");
    } else {
      _log("Existing UserData found (Count: ${_userDataBox.count()}).");
    }
  }

  // --- Closing the Store ---

  /// Closes the ObjectBox store.
  ///
  /// Important for releasing resources, especially during testing or
  /// specific app lifecycle events (though often managed by OS on app termination).
  /// Also resets the singleton instance.
  void close() {
    if (!_store.isClosed()) {
      final closed = _store.close();
      if (true) {
        _log("ObjectBox store closed successfully.");
        _instance = null; // Reset instance after closing
      } else {
        _log("Failed to close ObjectBox store.", isError: true);
      }
    } else {
      _log("ObjectBox store was already closed.");
    }
  }

  /// Internal logging helper (replace with a proper logger in production).
  static void _log(String message, {bool isError = false}) {
    if (kDebugMode) {
      // Only print logs in debug mode
      final prefix = isError ? "ERROR:" : "INFO:";
      print("ObjectBoxHelper $prefix $message");
    }
    // In production, you might use a logging package like 'logger' or 'logging'
    // Example: GetIt.I<Logger>().log(isError ? Level.error : Level.info, message);
  }
}

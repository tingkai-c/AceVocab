import 'package:flutter/material.dart';
import 'package:acevocab/app.dart'; // Your main app widget
import 'package:acevocab/data/objectbox_helper.dart'; // Import your helper

// 1. Make main asynchronous
Future<void> main() async {
  // 2. Ensure Flutter bindings are ready BEFORE using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize ObjectBox and wait for it to complete
  try {
    print("main: Initializing ObjectBox...");
    await ObjectBoxHelper.init(); // This performs the async setup
    print("main: ObjectBox initialized successfully.");

    // 4. Run the app ONLY if initialization was successful
    runApp(const App());
  } catch (e, s) {
    // Handle initialization errors (critical!)
    print("FATAL: Failed to initialize ObjectBox in main: $e\nStackTrace: $s");
    // Optional: You could show a specific error screen here instead of runApp
    // runApp(ErrorScreen(message: "Database failed to initialize. Please restart the app."));
    // Or exit, depending on how critical the DB is.
  }
}

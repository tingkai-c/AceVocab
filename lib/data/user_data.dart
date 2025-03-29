import 'package:objectbox/objectbox.dart';
import 'dart:convert'; // Required if storing complex settings as JSON
// Assume you have your ObjectBox helper class that provides the store
import './objectbox_helper.dart'; // Adjust the import path!

// --- ObjectBox Entity Definition (Remains the same) ---

@Entity()
class UserData {
  @Id()
  int id = 0;

  // --- User Progress ---
  int currentStreak;
  DateTime? lastStreakUpdate;

  // --- User Settings (Individual Fields Example) ---
  bool notificationsEnabled;
  String themeMode;
  double fontSizeMultiplier;

  // --- Constructor ---
  UserData({
    this.id = 0,
    this.currentStreak = 0,

    this.notificationsEnabled = true,
    this.themeMode = 'system',
    this.fontSizeMultiplier = 1.0,
  });

  // Creates a copy with default values but preserves the ID
  UserData reset() {
    return UserData(
      id: this.id, // Keep the original ID!
      currentStreak: 0,

      notificationsEnabled: true,
      themeMode: 'system',
      fontSizeMultiplier: 1.0,
    );
  }

  @override
  String toString() {
    return 'UserData(id: $id, currentStreak: $currentStreak, lastStreakUpdate: $lastStreakUpdate, notifications: $notificationsEnabled, theme: $themeMode, fontSize: $fontSizeMultiplier)';
  }
}

// --- UserDataHelper (Singleton, now relies on ObjectBox.getInstance() being awaited) ---
class UserDataHelper {
  // Private constructor
  UserDataHelper._internal();

  // Singleton instance (synchronous access)
  static final UserDataHelper instance = UserDataHelper._internal();

  // --- IMPORTANT ---
  // This helper now implicitly assumes that ObjectBox.getInstance()
  // has ALREADY completed successfully before its methods are called.
  // The Box access will FAIL if ObjectBox._instance is null.
  // Make sure to await ObjectBox.getInstance() in your main() function.

  // Get the box directly from the ObjectBox singleton
  Box<UserData> get _userBox {
    // Add a check for safety, although ideally this state shouldn't be reached
    // if initialization is done correctly in main().
    
    return ObjectBoxHelper.instance.userDataBox;
  }

  UserData readUserData() {
    // The ObjectBox helper's _ensureDefaultUserDataExists handles creation
    // on initialization. This just reads.
    UserData? userData = _userBox.getAll().firstOrNull;
    // If somehow still null (e.g., data deleted manually), create one.
    if (userData == null) {
      print(
        "UserDataHelper: Warning - Read failed, creating default UserData unexpectedly.",
      );
      userData = UserData();
      _userBox.put(userData);
    }
    return userData;
  }

  int updateUserData(UserData userData) {
    return _userBox.put(userData);
  }

  void updateUserStreak(int streak) {
    UserData d = readUserData();
    d.currentStreak = streak;
    updateUserData(d);
  }

  UserData resetUserData() {
    UserData currentData = readUserData();
    UserData defaultDataWithId = currentData.reset();
    updateUserData(defaultDataWithId);
    return defaultDataWithId;
  }

  Box<UserData> getBox() {
    return _userBox;
  }
}

import 'package:acevocab/features/practice/practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:acevocab/features/home/home_screen.dart';
import 'package:acevocab/features/settings/settings_screen.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persistent Bottom Navigation Bar Demo',
      home: PersistentTabView(
        tabs: [
          PersistentTabConfig(
            screen: HomeScreen(),
            item: ItemConfig(icon: Icon(Icons.home), title: "Home"),
          ),
          PersistentTabConfig(
            screen: PracticeScreen(),
            item: ItemConfig(
              icon: Icon(Icons.settings_accessibility),
              title: "Practice",
            ),
          ),

          PersistentTabConfig(
            screen: SettingsScreen(),
            item: ItemConfig(icon: Icon(Icons.settings), title: "Settings"),
          ),
        ],
        navBarBuilder:
            (navBarConfig) => Style10BottomNavBar(navBarConfig: navBarConfig),
      ),
    );
  }
}

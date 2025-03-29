import 'package:acevocab/features/settings/components/icon_style.dart';
import 'package:acevocab/features/settings/components/settings_group.dart';
import 'package:acevocab/features/settings/components/settings_item.dart';
import 'package:acevocab/fsrs/fsrs_storage.dart';
import 'package:acevocab/fsrs/word_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import CupertinoIcons

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ListView(
        children: [
          // const is okay here because the list structure is fixed
          // User card
          SettingsGroup(
            settingsGroupTitle: "Settings",
            backgroundColor: Colors.white, // You could make this a light blue.
            items: [
              SettingsItem(
                onTap: () {},
                icons: CupertinoIcons.pencil_outline,
                iconStyle: IconStyle(),
                title: 'Appearance',
                subtitle: "Make Ziar'App yours",
              ),
              SettingsItem(
                onTap: () {},
                icons: Icons.dark_mode_rounded,
                iconStyle: IconStyle(
                  iconsColor: Colors.white,
                  withBackground: true,
                  backgroundColor: Colors.red,
                ),
                title: 'Dark mode',
                subtitle: "Automatic",
                trailing: Switch(
                  value: false, //  Consider using a state variable for this.
                  onChanged: (value) {
                    value = value;
                  },
                ),
              ),
            ],
          ),
          SettingsGroup(
            // Add a comma here
            items: [
              SettingsItem(
                onTap: () {},
                icons: Icons.info_rounded,
                iconStyle: IconStyle(backgroundColor: Colors.purple),
                title: 'About',
                subtitle: "Learn more about this App",
              ),
            ],
          ),
          // You can add a settings title
          SettingsGroup(
            settingsGroupTitle: "Dangerous",
            items: [
              SettingsItem(
                onTap: () {},
                icons: Icons.exit_to_app_rounded,
                title: "Sign Out",
              ),
              SettingsItem(
                onTap: () async {
                  WordScheduler _w = await WordScheduler.getInstance();
                  _w.clearAllData();
                },
                icons: CupertinoIcons.delete_solid,
                title: "Delete account",
                titleStyle: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

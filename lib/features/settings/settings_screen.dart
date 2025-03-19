import 'package:flutter/material.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
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
            backgroundColor: Colors.blue, // You could make this a light blue.
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
                trailing: Switch.adaptive(
                  value: false, //  Consider using a state variable for this.
                  onChanged: (value) {},
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
                subtitle: "Learn more about Ziar'App",
              ),
            ],
          ),
          // You can add a settings title
          SettingsGroup(
            settingsGroupTitle: "Account",
            items: [
              SettingsItem(
                onTap: () {},
                icons: Icons.exit_to_app_rounded,
                title: "Sign Out",
              ),
              SettingsItem(
                onTap: () {},
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

import './settings_utils.dart';
import './settings_item.dart';
import 'package:flutter/material.dart';

/// This component group the Settings items (BabsComponentSettingsItem)
/// All one BabsComponentSettingsGroup have a title and the developper can improve the design.
class SettingsGroup extends StatelessWidget {
  final String? settingsGroupTitle;
  final TextStyle? settingsGroupTitleStyle;
  final List<SettingsItem> items;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  // Icons size
  final double? iconItemSize;

  SettingsGroup({
    this.settingsGroupTitle,
    this.settingsGroupTitleStyle,
    required this.items,
    this.backgroundColor,
    this.margin,
    this.iconItemSize = 25,
  });

  @override
  Widget build(BuildContext context) {
    if (this.iconItemSize != null)
      SettingsScreenUtils.settingsGroupIconSize = iconItemSize;

    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title
          (settingsGroupTitle != null)
              ? Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  settingsGroupTitle!,
                  style:
                      (settingsGroupTitleStyle == null)
                          ? TextStyle(fontSize: 25, fontWeight: FontWeight.bold)
                          : settingsGroupTitleStyle,
                ),
              )
              : Container(),
          // The SettingsGroup sections
          Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return items[index];
              },
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: ScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }
}

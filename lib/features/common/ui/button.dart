import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Color color;
  final Color colorText;
  final double widget;
  final bool showProgress;

  Button(
    this.text, {
    required this.onPressed,
    required this.color,
    required this.colorText,
    required this.widget,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    child: ElevatedButton(
      onPressed: onPressed,
      child:
          showProgress
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(text, style: TextStyle(color: Colors.white, fontSize: 22)),
    ),
  );
}

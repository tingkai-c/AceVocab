import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ClickableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  const ClickableText({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  State<ClickableText> createState() => _ClickableTextState();
}

class MyDictionaryBrowser extends ChromeSafariBrowser {
  @override
  void onOpened() {
    print("ChromeSafari browser opened");
  }

  @override
  void onCompletedInitialLoad(bool? didLoadSuccessfully) {
    print("ChromeSafari browser initial load completed: $didLoadSuccessfully");
  }

  @override
  void onClosed() {
    print("ChromeSafari browser closed");
  }
}

class _ClickableTextState extends State<ClickableText> {
  final MyDictionaryBrowser _browser =
      MyDictionaryBrowser(); // Instance of our browser

  void _showDictionary(String word) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showErrorDialog(
        "No Internet Connection",
        "Please check your internet connection and try again.",
      );
      return;
    }

    final String cleanWord = word.replaceAll(RegExp(r'[^\w\s]+'), '');
    final String encodedWord = Uri.encodeComponent(cleanWord);
    final String urlString =
        'https://dictionary.cambridge.org/zht/%E8%A9%9E%E5%85%B8/%E8%8B%B1%E8%AA%9E-%E6%BC%A2%E8%AA%9E-%E7%B9%81%E9%AB%94/$encodedWord';
    final WebUri url = WebUri(urlString);

    try {
      await _browser.open(
        url: url,
        settings: ChromeSafariBrowserSettings(
          // Example settings, adjust as needed
          shareState: CustomTabsShareState.SHARE_STATE_OFF, // Disable sharing
          barCollapsingEnabled: true, // Collapse toolbar on scroll
          presentationStyle: ModalPresentationStyle.FULL_SCREEN,
          // Add other settings here from the documentation you provided
        ),
      );
    } catch (e) {
      _showErrorDialog("Error Loading Dictionary", "Error occurred: $e");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<TextSpan> _buildTextSpans(String text) {
    final words = text.split(' ');
    final List<TextSpan> spans = [];

    for (final word in words) {
      spans.add(
        TextSpan(
          text: '$word ',
          recognizer:
              TapGestureRecognizer()..onTap = () => _showDictionary(word),
          style:
              widget.style != null
                  ? widget.style!.copyWith(color: Colors.black)
                  : const TextStyle(color: Colors.black),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: _buildTextSpans(widget.text),
        style: widget.style ?? DefaultTextStyle.of(context).style,
      ),
      textAlign: widget.textAlign ?? TextAlign.start,
      textDirection: widget.textDirection,
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
    );
  }
}

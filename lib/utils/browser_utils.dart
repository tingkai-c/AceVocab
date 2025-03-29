import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Custom Browser class (can be kept private if only used here)
class _MyDictionaryBrowser extends ChromeSafariBrowser {
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

// Instance of the browser (kept private within the utility file)
final _MyDictionaryBrowser _browser = _MyDictionaryBrowser();

/// Shows an error dialog.
void _showErrorDialog(BuildContext context, String title, String message) {
  // Ensure the context is still valid before showing the dialog
  if (!context.mounted) return;
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

/// Opens an in-app browser to the Cambridge Dictionary page for the given word.
///
/// Checks for internet connectivity before attempting to open the browser.
/// Shows an error dialog if there's no connection or if an error occurs.
Future<void> showDictionaryPopup(BuildContext context, String word) async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    _showErrorDialog(
      context,
      "No Internet Connection",
      "Please check your internet connection and try again.",
    );
    return;
  }

  // Clean and encode the word for the URL
  final String cleanWord = word.trim().replaceAll(RegExp(r'[^\w\s]+'), '');
  if (cleanWord.isEmpty) {
    _showErrorDialog(context, "Invalid Word", "Cannot look up an empty word.");
    return;
  }
  final String encodedWord = Uri.encodeComponent(cleanWord);
  final String urlString =
      'https://dictionary.cambridge.org/zht/%E8%A9%9E%E5%85%B8/%E8%8B%B1%E8%AA%9E-%E6%BC%A2%E8%AA%9E-%E7%B9%81%E9%AB%94/$encodedWord';
  final WebUri url = WebUri(urlString);

  try {
    // Open the browser
    await _browser.open(
      url: url,
      settings: ChromeSafariBrowserSettings(
        shareState: CustomTabsShareState.SHARE_STATE_OFF,
        barCollapsingEnabled: true,
        presentationStyle:
            ModalPresentationStyle.POPOVER, // Changed for potentially better UX
        // Add other settings as needed
      ),
    );
  } catch (e) {
    // Show error dialog on failure
    _showErrorDialog(
      context,
      "Error Loading Dictionary",
      "Could not open dictionary: $e",
    );
  }
}

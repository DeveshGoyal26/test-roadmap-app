import 'package:flutter/material.dart';

class CustomSnackBar {
  // Main show method with all options
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red[900] : Colors.white,
        duration: duration,
        margin: const EdgeInsets.all(0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        elevation: 6,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: isError ? Colors.white : Colors.black,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            onDismissed?.call();
          },
        ),
      ),
    );
  }

  // Convenience method for success messages
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
  }) {
    show(
      context: context,
      message: message,
      isError: false,
      duration: duration,
      onDismissed: onDismissed,
    );
  }

  // Convenience method for error messages
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
  }) {
    show(
      context: context,
      message: message,
      isError: true,
      duration: duration,
      onDismissed: onDismissed,
    );
  }

  // Legacy support for the old function-based API
  @Deprecated('Use CustomSnackBar.show() instead')
  static void showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    show(context: context, message: message, isError: isError);
  }
}

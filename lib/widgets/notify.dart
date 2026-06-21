import 'package:flutter/material.dart';
import '../core/theme_notifier.dart';

class Notify {
  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : (ThemeNotifier.isDarkMode ? const Color(0xFF6200EE) : Colors.green),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF6200EE)),
            const SizedBox(width: 20),
            Text(message, style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }
}

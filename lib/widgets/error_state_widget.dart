// lib/widgets/error_state_widget.dart
import 'package:flutter/material.dart';
import 'package:cleandesk_ai/core/theme/app_theme.dart';
import 'package:cleandesk_ai/data/services/api_service.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final ApiErrorType? errorType;
  final VoidCallback onRetry;
  final bool isFullScreen;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.errorType,
    required this.onRetry,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.error_outline;
    String title = 'Something went wrong';

    if (errorType == ApiErrorType.network) {
      icon = Icons.wifi_off_outlined;
      title = 'No Internet Connection';
    } else if (errorType == ApiErrorType.server) {
      icon = Icons.dns_outlined;
      title = 'Server is currently down';
    }

    final content = Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.grey400),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.grey600, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.black,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );

    if (isFullScreen) {
      return Center(child: SingleChildScrollView(child: content));
    }
    return content;
  }
}

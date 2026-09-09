import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../errors/failures.dart';
import 'empty_state.dart';

/// Failure view. Network problems get their own copy because that is the
/// case users actually hit on mobile in Uzbekistan.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.isOffline = false,
  });

  ErrorState.fromFailure(Failure failure, {super.key, this.onRetry})
      : message = failure.message,
        title = null,
        isOffline = failure is NetworkFailure;

  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return EmptyState(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      tone: isOffline ? c.warning : c.danger,
      title: title ?? (isOffline ? 'Internet aloqasi yo‘q' : 'Nimadir xato ketdi'),
      subtitle: message,
      actionLabel: onRetry != null ? 'Qayta urinish' : null,
      onAction: onRetry,
    );
  }
}

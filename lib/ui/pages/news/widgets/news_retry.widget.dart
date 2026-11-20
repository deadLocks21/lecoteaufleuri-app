import 'package:flutter/material.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_error_message.dart';

/// Ce qui n'a pas pu être chargé, et de quoi réessayer.
class NewsRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const NewsRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Le message de [error], s'il vient des nouvelles.
  NewsRetryView.of(Object error, {super.key, required this.onRetry})
    : message = newsErrorMessage(
        error is NewsException ? error.code : NewsErrorCode.unknown,
      );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, key: const Key('newsError'), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay_detail.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_space.provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/stay_error_message.dart';

/// Le séjour ouvert une fois lu ([builder]) ; pendant sa lecture, un
/// indicateur ; en cas d'échec, le message et de quoi réessayer.
class StaySpaceView extends ConsumerWidget {
  final String stayId;
  final Widget Function(BuildContext context, StaySpaceDto space) builder;

  const StaySpaceView({super.key, required this.stayId, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(staySpaceProvider(stayId));
    return switch ((space.value, space.error)) {
      (final StaySpaceDto value, _) => builder(context, value),
      (_, final Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stayErrorMessage(
                  error is StayException ? error.code : StayErrorCode.unknown,
                ),
                key: const Key('stayError'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(staySpaceProvider(stayId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

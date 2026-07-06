import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pro_unlock_service.dart';

class ProUnlockBanner extends ConsumerWidget {
  const ProUnlockBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proUnlockControllerProvider);
    final controller = ref.read(proUnlockControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    if (state.isUnlocked) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: colors.tertiaryContainer.withValues(alpha: .65),
          border: Border.all(color: colors.tertiary.withValues(alpha: .5)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: colors.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pro unlocked: unlimited events and custom schema definition.',
                style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2748), Color(0xFF061426)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD6A941).withValues(alpha: .62)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFD6A941)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unlock Pro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                state.price ?? proUnlockFallbackPrice,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFD6A941),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlimited events per day and custom schema definition in this app.',
            style: TextStyle(color: Color(0xFFD7E3F4), height: 1.35),
          ),
          if (state.message != null) ...[
            const SizedBox(height: 8),
            Text(state.message!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isLoading ? null : controller.buyPro,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(state.isLoading ? 'Please wait...' : 'Unlock Pro'),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: state.isLoading ? null : controller.restorePurchases,
                child: const Text('Restore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

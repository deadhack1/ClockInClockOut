import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/duration_formatter.dart';
import '../controller/shift_controller.dart';


class ClockScreen extends ConsumerWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final shift = ref.watch(shiftControllerProvider);
    final ctrl = ref.read(shiftControllerProvider.notifier);

    final statusText = shift.isClockedIn
        ? (shift.onBreak ? 'On break' : 'On shift')
        : 'Off shift';

    final statusDot = shift.isClockedIn
        ? (shift.onBreak ? Colors.orange : Colors.green)
        : Colors.grey;

    final primaryLabel = shift.isClockedIn ? 'Clock Out' : 'Clock In';
    final primaryIcon = shift.isClockedIn ? Icons.stop_rounded : Icons.play_arrow_rounded;

    final breakPrimaryEnabled = shift.isClockedIn && !shift.onBreak;
    final breakEndEnabled = shift.isClockedIn && shift.onBreak;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Clock',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: statusDot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status: $statusText',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('Today', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timer card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    shift.isClockedIn ? 'Shift Timer' : 'Ready',
                    style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatHms(shift.elapsed),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shift.isClockedIn
                        ? (shift.onBreak ? 'Break running' : 'Tracking time')
                        : 'Clock in to start tracking',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  if (shift.breakElapsed > Duration.zero) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Breaks: ${formatHm(shift.breakElapsed)}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Clock In / Out button
            SizedBox(
              height: 58,
              child: FilledButton.icon(
                onPressed: () {
                  if (shift.isClockedIn) {
                    ctrl.clockOut();
                  } else {
                    ctrl.clockIn();
                  }
                },
                icon: Icon(primaryIcon),
                label: Text(
                  primaryLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Break buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: breakPrimaryEnabled ? ctrl.startBreak : null,
                    icon: const Icon(Icons.coffee),
                    label: const Text('Start Break'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: breakEndEnabled ? ctrl.endBreak : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('End Break'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Stats (still placeholder, but wired to shift time)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _MiniCard(title: "Today’s Hours", value: formatHm(shift.elapsed)),
                  const _MiniCard(title: "This Week", value: "0h 0m"),
                  const _MiniCard(title: "Overtime", value: "0h 0m"),
                  const _MiniCard(title: "Next Pay", value: "\$0.00"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  const _MiniCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
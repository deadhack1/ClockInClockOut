import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/duration_formatter.dart';
import '../controller/timesheet_controller.dart';

class TimesheetsScreen extends ConsumerWidget {
  const TimesheetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(timesheetControllerProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Timesheets',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Expanded(
                child: entriesAsync.when(
                    loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                    error: (e, _) => Center(
                          child: Text('Error loading timesheets $e'),
                        ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Center(
                          child: Text('No completed shifts yet'),
                        );
                      }
                      return ListView.separated(
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            title: Text('${entry.clockIn}=>${entry.clockOut}'),
                            subtitle: Text(
                              'Worked: ${entry.worked.inHours}h',
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(
                          height: 10,
                        ),
                        itemCount: entries.length,
                      );
                    }),
              ),
              //     if (entries.isNotEmpty)
              //       TextButton.icon(
              //         onPressed: () {
              //           ref.read(timesheetControllerProvider.notifier).clearAll();
              //         },
              //         icon: const Icon(Icons.delete_outline),
              //         label: const Text('Clear'),
              //       ),
              //   ],
              // ),
              // const SizedBox(height: 16),
              //
              // if (entries.isEmpty)
              //   Expanded(
              //     child: Center(
              //       child: Text(
              //         'No completed shifts yet',
              //         style: theme.textTheme.titleMedium?.copyWith(
              //           color: cs.onSurfaceVariant,
              //         ),
              //       ),
              //     ),
              //   )
              // else
              //   Expanded(
              //     child: ListView.separated(
              //       itemCount: entries.length,
              //       separatorBuilder: (_, __) => const SizedBox(height: 10),
              //       itemBuilder: (context, index) {
              //         final entry = entries[index];
              //
              //         final dateText =
              //         DateFormat('MMM d, yyyy').format(entry.clockIn);
              //
              //         final inText =
              //         DateFormat('h:mm a').format(entry.clockIn);
              //
              //         final outText =
              //         DateFormat('h:mm a').format(entry.clockOut);
              //
              //         return Container(
              //           padding: const EdgeInsets.all(14),
              //           decoration: BoxDecoration(
              //             color: cs.surface,
              //             borderRadius: BorderRadius.circular(16),
              //             border: Border.all(
              //               color: cs.outlineVariant.withOpacity(0.5),
              //             ),
              //           ),
              //           child: Row(
              //             children: [
              //               Container(
              //                 width: 48,
              //                 height: 48,
              //                 decoration: BoxDecoration(
              //                   color: cs.primary.withOpacity(0.12),
              //                   borderRadius: BorderRadius.circular(12),
              //                 ),
              //                 child: Icon(
              //                   Icons.access_time,
              //                   color: cs.primary,
              //                 ),
              //               ),
              //               const SizedBox(width: 12),
              //
              //               Expanded(
              //                 child: Column(
              //                   crossAxisAlignment: CrossAxisAlignment.start,
              //                   children: [
              //                     Text(
              //                       dateText,
              //                       style: const TextStyle(
              //                         fontWeight: FontWeight.w800,
              //                       ),
              //                     ),
              //                     const SizedBox(height: 4),
              //                     Text(
              //                       'In $inText • Out $outText',
              //                       style: TextStyle(
              //                         color: cs.onSurfaceVariant,
              //                       ),
              //                     ),
              //                     if (entry.breaks > Duration.zero)
              //                       Padding(
              //                         padding:
              //                         const EdgeInsets.only(top: 4),
              //                         child: Text(
              //                           'Breaks: ${formatHm(entry.breaks)}',
              //                           style: TextStyle(
              //                             color: cs.onSurfaceVariant,
              //                           ),
              //                         ),
              //                       ),
              //                   ],
              //                 ),
              //               ),
              //
              //               Text(
              //                 formatHm(entry.worked),
              //                 style: const TextStyle(
              //                   fontWeight: FontWeight.w900,
              //                   fontSize: 16,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         );
              //       },
              //     ),
              //   ),
            ],
          ),
        ],
      ),
    ));
  }
}

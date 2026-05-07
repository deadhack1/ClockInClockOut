import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/formatters/duration_formatter.dart';
import '../providers/admin_timesheet_provider.dart';
import '../models/admin_timesheet_entry.dart';

class ManageTimesheetsScreen extends ConsumerWidget {
  const ManageTimesheetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(adminTimesheetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Timesheets', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _TimesheetTile(entry: entry);
          },
        ),
      ),
    );
  }
}

class _TimesheetTile extends ConsumerWidget {
  final AdminTimesheetEntry entry;
  const _TimesheetTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(entry.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${dateFormat.format(entry.clockIn)}'),
            Text('${timeFormat.format(entry.clockIn)} - ${timeFormat.format(entry.clockOut)}'),
            Text('Worked: ${formatHm(entry.worked)} (Breaks: ${formatHm(entry.breaks)})'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this timesheet entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(adminTimesheetProvider.notifier).deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    DateTime newIn = entry.clockIn;
    DateTime newOut = entry.clockOut;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Timesheet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Clock In'),
                subtitle: Text('${DateFormat('yyyy-MM-dd HH:mm').format(newIn)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: newIn,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(newIn),
                  );
                  if (time == null) return;
                  setState(() => newIn = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              ListTile(
                title: const Text('Clock Out'),
                subtitle: Text('${DateFormat('yyyy-MM-dd HH:mm').format(newOut)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: newOut,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(newOut),
                  );
                  if (time == null) return;
                  setState(() => newOut = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      ref.read(adminTimesheetProvider.notifier).updateEntry(entry.id, newIn, newOut);
    }
  }
}

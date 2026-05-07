import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'admin_payroll_provider.dart';
import '../../../core/formatters/duration_formatter.dart';

final payrollExportProvider = Provider((ref) => PayrollExportService(ref));

class PayrollExportService {
  final Ref _ref;

  PayrollExportService(this._ref);

  Future<void> exportToCsv() async {
    final payroll = _ref.read(adminPayrollProvider);
    
    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add([
      'Employee Name',
      'Total Worked (H:M)',
      'Overtime (H:M)',
      'Total Pay (\$)',
    ]);

    for (var summary in payroll) {
      rows.add([
        summary.employeeName,
        formatHm(summary.totalWorked),
        formatHm(summary.overtime),
        summary.totalPay.toStringAsFixed(2),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/payroll_report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    
    await file.writeAsString(csvData);
    
    await Share.shareXFiles([XFile(path)], text: 'Payroll Report');
  }
}

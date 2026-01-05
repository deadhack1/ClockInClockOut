import 'package:clock_in_clock_out/app/router.dart';
import 'package:clock_in_clock_out/app/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClockInClockOut extends ConsumerWidget {
  const ClockInClockOut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router =ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Clock In/Out',
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}
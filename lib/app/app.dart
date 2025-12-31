import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClockInClockOut {
  const ClockInClockOut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router =ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Clock In/Out',
      theme: buildTheme(),
      routerConfig: router,
    );;
  }
}
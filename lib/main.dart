import 'package:clock_in_clock_out/temp/Screen/ClockInClockOut.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main ()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kebtrzjbwjwcuueymaqw.supabase.co',
    anonKey: 'sb_publishable_soP1ru4_Ebt1-Gj6H2vpIA_QKElv4Qk',
  );
  runApp(const ProviderScope(child: ClockInClockOut()));

}
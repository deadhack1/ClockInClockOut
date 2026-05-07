import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/shared_prefs_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/profile.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(supabase, prefs);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.session?.user;
});

final userProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  // Listen to auth changes and invalidate this provider when signing out/in
  // but for now, the user dependency is enough.
  
  return ref.watch(authRepositoryProvider).getProfile(user.id);
});

final organizationEmployeesProvider = FutureProvider<List<Profile>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile?.organizationId == null) return [];
  return ref.read(authRepositoryProvider).getEmployees(profile!.organizationId!);
});

final selectedKioskEmployeeProvider = StateProvider<Profile?>((ref) => null);

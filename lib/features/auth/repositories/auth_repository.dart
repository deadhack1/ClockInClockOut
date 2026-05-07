import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/crypto_utils.dart';
import '../models/profile.dart';

class AuthRepository {
  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _profileKey = 'cached_profile';

  AuthRepository(this._client, this._prefs);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<Profile?> getProfile(String id) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      
      final profile = Profile.fromJson(data);
      // Cache locally
      await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      return profile;
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        // User record not found in database (likely deleted)
        await _prefs.remove(_profileKey);
        // Explicitly sign out from Supabase to clear the local session
        await _client.auth.signOut();
        rethrow;
      }
      // For other errors (like network issues), try to return cached profile
      final cached = _prefs.getString(_profileKey);
      if (cached != null) {
        return Profile.fromJson(jsonDecode(cached));
      }
      rethrow;
    }
  }

  Future<void> createOrganization(String name, String adminId) async {
    final orgData = await _client.from('organizations').insert({
      'name': name,
      'admin_id': adminId,
    }).select().single();

    final orgId = orgData['id'];

    await _client.from('profiles').update({
      'organization_id': orgId,
      'role': 'admin',
    }).eq('id', adminId);
  }

  Future<AuthResponse> signUpAdmin({
    required String email,
    required String password,
    required String fullName,
    required String organizationName,
  }) async {
    // 1. Create the user auth profile in Supabase Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    ).catchError((e)=> throw Exception("Failed to create user in auth: $e"));

    final user = response.user;
    if (user != null) {
      print("failed to create the user in auth");
      // 2. Create the organization first to get its ID
      try {
        final orgData = await _client.from('organizations').insert({
          'name': organizationName,
          'admin_id': user.id,
        }).select().single();

        final orgId = orgData['id'];

        // 3. Create the corresponding profile entry linked to the auth user and organization
        await _client.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'role': 'admin',
          'organization_id': orgId,
        });
      } on Exception catch (e) {
        throw e;
        SnackBar(content: Text("Create Organization failed: $e"));

        // TODO
      }
    }

    return response;
  }

  Future<void> createEmployee({
    required String email,
    required String password,
    required String fullName,
    required String organizationId,
    required int hourlyRateCents,
  }) async {
    final response = await _client.functions.invoke(
      'create-employee-user',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'organization_id': organizationId,
        'hourly_rate_cents': hourlyRateCents,
      },
    ).catchError((e){
      throw Exception("Failed to create employee via Edge Function: $e");
    });

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Failed to create employee via Edge Function';
      throw Exception(error);
    }
  }

  Future<List<Profile>> getEmployees(String organizationId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('organization_id', organizationId)
        .eq('role', 'employee')
        .order('full_name');
    
    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  Future<void> updateEmployee(String profileId, Map<String, dynamic> updates) async {
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', profileId);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // 1. Create the user auth profile in Supabase Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
print("adding the user to the profile table");
    if (response.user != null) {
      // 2. Add its entry to profiles table
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'role': 'employee',
      });
    }

    return response;
  }


}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_model.dart' as model;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  // Lazy access to client to prevent crash if not initialized
  supabase.SupabaseClient? get _client {
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Auth
  Future<model.User?> login(String email, String password) async {
    final client = _client;
    if (client == null) return null; // Offline/Not Configured

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch user details from public.users table if you have custom user data
        // For now, return a basic User object based on Auth response
        return model.User(
          id: response.user!.id,
          username: response.user!.email ?? '',
          email: response.user!.email,
          name: response.user!.userMetadata?['name'] ?? 'User',
          role: response.user!.userMetadata?['role'] ?? 'cashier',
          password: '', // We don't store the password hash here
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Supabase Login Error: $e');
      return null;
    }
  }

  // Sync Logic (Placeholder)
  Future<void> syncData(
    String table,
    List<Map<String, dynamic>> localData,
  ) async {
    final client = _client;
    if (client == null) return;

    try {
      if (localData.isNotEmpty) {
        await client.from(table).upsert(localData);
      }
    } catch (e) {
      debugPrint('Sync Error for $table: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchChanges(
    String table,
    DateTime lastSync,
  ) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client
          .from(table)
          .select()
          .gt('updated_at', lastSync.toIso8601String());
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch Changes Error for $table: $e');
      return [];
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  String _role = 'visitor';
  bool _loading = true;
  StreamSubscription? _sub;

  User? get user => _user;
  String get role => _role;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _role == 'admin';
  bool get isLoading => _loading;

  AuthService() {
    _init();
  }

Future<String> ensureOrgId({
  required String name,
  required String description,
}) async {
  final uid = _user?.id;
  if (uid == null) throw Exception('Not logged in');

  final existing = await _supabase
      .from('organizations')
      .select('id')
      .eq('owner_id', uid)
      .maybeSingle();
  if (existing != null) return existing['id'] as String;

  final res = await _supabase
      .from('organizations')
      .insert({
        'name': name,
        'description': description,
        'owner_id': uid,
      })
      .select()
      .single();
  return res['id'] as String;
}

  Future<void> _init() async {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      await _loadRole();
    }
    _loading = false;
    notifyListeners();

    _sub = _supabase.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        await _loadRole();
      } else {
        _role = 'visitor';
      }
      notifyListeners();
    });
  }

  Future<void> _loadRole() async {
    if (_user == null) return;
    try {
      final res = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _user!.id)
          .maybeSingle();
      _role = (res?['role'] as String?) ?? 'visitor';
    } catch (_) {
      _role = 'visitor';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String role,
    String? fullName,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) return 'Signup failed';

     try {
  await _supabase.from('profiles').upsert({
    'id': res.user!.id,
    'email': email,
    'role': role,
    'full_name': fullName,
  });
} catch (e) {
  // Trigger may have already created the row — try update instead
  try {
    await _supabase
        .from('profiles')
        .update({'role': role, 'full_name': fullName})
        .eq('id', res.user!.id);
  } catch (e2) {
    // Silent — profile still created by trigger
  }
}

      if (res.session == null) {
        return 'CHECK_EMAIL';
      }
      _role = role;
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Signup error: $e';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _loadRole();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Sign in error: $e';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    _role = 'visitor';
    notifyListeners();
  }

  Future<String?> updateRole(String role) async {
    if (_user == null) return 'Not logged in';
    try {
      await _supabase
          .from('profiles')
          .update({'role': role}).eq('id', _user!.id);
      _role = role;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Role update failed: $e';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
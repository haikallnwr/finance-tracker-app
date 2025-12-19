import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  String? _username;
  String? _email;

  bool get isLoading => _isLoading;
  String? get username => _username;
  String? get email => _email;
  bool get isAuthenticated => _token != null;

  // --- REGISTER ---
  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      _setLoading(false);
      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      print("Register Error: $e");
      return false;
    }
  }

  // --- LOGIN ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        // Sesuai controller auth: user ada di dalam object 'user'
        _username = data['user']['username'];
        _email = data['user']['email'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('username', _username!);
        await prefs.setString('email', _email!);

        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      print("Login Error: $e");
      return false;
    }
  }

  // --- LOGOUT ---
  void logout() async {
    _token = null;
    _username = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // --- UPDATE PROFILE (Sesuai Controller User Kamu) ---
  Future<bool> updateProfile(String newUsername, String newEmail) async {
    _setLoading(true);
    // Route: /api/user/updateProfile
    final url = Uri.parse('${ApiConstants.baseUrl}/user/updateProfile');

    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'username': newUsername, 'email': newEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Sesuai userController.updateUser: res.json({ update })
        final updatedUser = data['update'];

        if (updatedUser != null) {
          _username = updatedUser['username'];
          _email = updatedUser['email'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', _username!);
          await prefs.setString('email', _email!);
        }

        _setLoading(false);
        return true;
      } else {
        print("Update Failed: ${response.body}");
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print("Update Profile Error: $e");
      _setLoading(false);
      return false;
    }
  }

  // --- CHANGE PASSWORD (Sesuai Controller Auth Kamu) ---
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    // Route: /api/auth/changePassword
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/changePassword');

    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      _setLoading(false);
      // Controller auth mengembalikan 200 OK jika sukses
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Change Password Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Change Password Error: $e");
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    notifyListeners();
  }
}

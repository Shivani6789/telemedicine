import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _patientId;
  String? _name;
  String? _role;
  // linkedDoctorId = the Doctor collection _id (MongoDB ObjectId hex string)
  // This is what the appointments endpoint expects, NOT the User._id
  String? _linkedDoctorId;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get patientId => _patientId;
  String? get name => _name;
  String? get role => _role;
  // For doctor users: this is the Doctor document _id used to fetch appointments
  String? get linkedDoctorId => _linkedDoctorId;
  bool get isLoading => _isLoading;
  bool get isDoctor => _role == 'doctor';

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _isAuthenticated = true;
      _userId = prefs.getString('userId');
      _patientId = prefs.getString('patientId');
      _name = prefs.getString('name');
      _role = prefs.getString('role') ?? 'patient';
      _linkedDoctorId = prefs.getString('linkedDoctorId');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      if (res.containsKey('token')) {
        await _saveSession(res);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Surface the error message from the server
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String name, String email, String password, String phone,
      String age, String gender) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res =
          await ApiService.signup(name, email, password, phone, age, gender);
      if (res.containsKey('token')) {
        await _saveSession(res);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Signup error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _saveSession(Map<String, dynamic> res) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', res['token']);
    await prefs.setString('userId', res['_id'].toString());
    await prefs.setString('patientId', res['patientId'] ?? '');
    await prefs.setString('name', res['name']);
    await prefs.setString('role', res['role'] ?? 'patient');

    // linkedDoctorId is the Doctor document's _id (a plain hex ObjectId string
    // like "6619f3..."). Store it directly — do NOT call toString() on a
    // potential ObjectId instance, which would give "Instance of 'Object'".
    final rawLinked = res['linkedDoctorId'];
    final linkedStr = rawLinked != null ? rawLinked.toString() : '';
    if (linkedStr.isNotEmpty && linkedStr != 'null') {
      await prefs.setString('linkedDoctorId', linkedStr);
    } else {
      await prefs.remove('linkedDoctorId');
    }

    _isAuthenticated = true;
    _userId = res['_id'].toString();
    _patientId = res['patientId'];
    _name = res['name'];
    _role = res['role'] ?? 'patient';
    _linkedDoctorId = (linkedStr.isNotEmpty && linkedStr != 'null') ? linkedStr : null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isAuthenticated = false;
    _userId = null;
    _patientId = null;
    _name = null;
    _role = null;
    _linkedDoctorId = null;
    notifyListeners();
  }
}

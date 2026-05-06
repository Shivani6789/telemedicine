import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class DataProvider extends ChangeNotifier {
  List<dynamic> _doctors = [];
  List<dynamic> _records = [];
  List<dynamic> _pharmacies = [];
  bool _isLoading = false;
  bool _isOffline = false;

  List<dynamic> get doctors => _doctors;
  List<dynamic> get records => _records;
  List<dynamic> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  Future<void> loadDoctors() async {
    _isLoading = true;
    notifyListeners();
    try {
      _doctors = await ApiService.getDoctors();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_doctors', jsonEncode(_doctors));
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_doctors');
      if (cached != null) _doctors = jsonDecode(cached);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecords(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await ApiService.getRecords(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_records', jsonEncode(_records));
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_records');
      if (cached != null) _records = jsonDecode(cached);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> bookOffline(
      String doctorId, String date, String slot,
      String pName, int pAge, String pGender) async {
    return await ApiService.bookOffline(doctorId, date, slot, pName, pAge, pGender);
  }

  Future<Map<String, dynamic>> bookOnline(
      String doctorId, String pName, int pAge, String pGender) async {
    return await ApiService.bookOnline(doctorId, pName, pAge, pGender);
  }

  /// Returns AI-ranked doctor recommendations + condition/severity.
  /// Shape: { condition, severity, specialization, message, recommendations: [...] }
  Future<Map<String, dynamic>> analyzeSymptoms(List<String> symptoms) async {
    return await ApiService.analyzeSymptoms(symptoms);
  }

  Future<void> searchPharmacies(String medicine) async {
    _isLoading = true;
    notifyListeners();
    try {
      _pharmacies = await ApiService.searchPharmacies(medicine);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_pharmacies_$medicine', jsonEncode(_pharmacies));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_pharmacies_$medicine');
      if (cached != null) {
        _pharmacies = jsonDecode(cached);
      } else {
        _pharmacies = [];
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNearbyPharmacies(double lat, double lng) async {
    _isLoading = true;
    notifyListeners();
    try {
      _pharmacies = await ApiService.getNearbyPharmacies(lat, lng);
    } catch (e) {
      debugPrint('Error fetching nearby pharmacies: $e');
      _pharmacies = [];
    }
    _isLoading = false;
    notifyListeners();
  }
}


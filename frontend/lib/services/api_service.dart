import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Chrome (web): 'localhost'; Android emulator: '10.0.2.2'
  // Physical device on same WiFi: replace with your PC's LAN IP
  static String get baseUrl =>
      kIsWeb ? "http://localhost:5000/api" : "http://192.168.1.6:5000/api";

  // Platform-aware socket URL:
  // Web (Chrome) → localhost | Android emulator → 10.0.2.2
  static String get socketUrl =>
      kIsWeb ? 'http://localhost:5000' : 'http://192.168.1.6:5000';

  // ── Helpers ────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getDefaultHeaders() async {
    final token = await getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // ── Auth ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> signup(String name, String email,
      String password, String phone, String age, String gender) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'age': int.parse(age),
        'gender': gender
      }),
    );
    return jsonDecode(response.body);
  }

  // ── Doctors ─────────────────────────────────────────────────────

  static Future<List<dynamic>> getDoctors() async {
    final headers = await getDefaultHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl/doctors'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load doctors');
  }

  static Future<List<dynamic>> getDoctorsBySpecialization(
      String specialization) async {
    final headers = await getDefaultHeaders();
    final response = await http.get(
      Uri.parse(
          '$baseUrl/doctors/by-specialization?specialization=$specialization'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load doctors by specialization');
  }

  static Future<Map<String, dynamic>> toggleDoctorAvailability(
      String doctorId) async {
    final headers = await getDefaultHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/doctors/$doctorId/availability'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to toggle availability');
  }

  // ── Appointments ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> bookOffline(String doctorId, String date,
      String slot, String pName, int pAge, String pGender) async {
    final headers = await getDefaultHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/book'),
      headers: headers,
      body: jsonEncode({
        'doctorId': doctorId,
        'date': date,
        'slot': slot,
        'patientName': pName,
        'patientAge': pAge,
        'patientGender': pGender
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> bookOnline(
      String doctorId, String pName, int pAge, String pGender) async {
    final headers = await getDefaultHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/online-consult'),
      headers: headers,
      body: jsonEncode({
        'doctorId': doctorId,
        'patientName': pName,
        'patientAge': pAge,
        'patientGender': pGender
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getDoctorAppointments(String doctorId) async {
    final headers = await getDefaultHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/doctor/$doctorId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load doctor appointments: ${response.body}');
  }

  // ── Symptoms (AI-assisted) ────────────────────────────────────────

  static Future<Map<String, dynamic>> analyzeSymptoms(
      List<String> symptoms) async {
    final headers = await getDefaultHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/symptoms/analyze'),
      headers: headers,
      body: jsonEncode({'symptoms': symptoms}),
    );
    return jsonDecode(response.body);
  }

  // ── Medical Records ──────────────────────────────────────────────

  static Future<List<dynamic>> getRecords(String patientId,
      {String? search, String? date, String? category}) async {
    final headers = await getDefaultHeaders();
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (category != null && category.isNotEmpty) params['category'] = category;
    final uri = Uri.parse('$baseUrl/records/$patientId')
        .replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load records');
  }

  static Future<Map<String, dynamic>> addRecord(String doctorName,
      String consultationType, String category, Map<String, dynamic> details) async {
    final headers = await getDefaultHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/records/add'),
      headers: headers,
      body: jsonEncode({
        'doctorName': doctorName,
        'consultationType': consultationType,
        'category': category,
        'details': details
      }),
    );
    return jsonDecode(response.body);
  }

  // ── Prescriptions ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitPrescription({
    required String patientId,
    String? appointmentId,
    required String diagnosis,
    required List<Map<String, dynamic>> medicines,
    String notes = '',
  }) async {
    final headers = await getDefaultHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions'),
      headers: headers,
      body: jsonEncode({
        'patientId': patientId,
        if (appointmentId != null) 'appointmentId': appointmentId,
        'diagnosis': diagnosis,
        'medicines': medicines,
        'notes': notes,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPatientPrescriptions(
      String patientId) async {
    final headers = await getDefaultHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions/patient/$patientId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load prescriptions');
  }

  // ── Pharmacies ───────────────────────────────────────────────────

  static Future<List<dynamic>> searchPharmacies(String medicine) async {
    final headers = await getDefaultHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacies/search?medicine=$medicine'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to search pharmacies');
  }

  static Future<List<dynamic>> getNearbyPharmacies(double lat, double lng) async {
    final headers = await getDefaultHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacies/nearby?lat=$lat&lng=$lng'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch nearby pharmacies');
  }
}

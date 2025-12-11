import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../models/user.dart';
import '../models/booking.dart'; // ⬅️ TAMBAH INI

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // ============= STATE USER =============
  static AppUser? currentUser;

  // header standar (pakai token kalau nanti sudah ada)
  static Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{'Accept': 'application/json'};

    if (withAuth && (currentUser?.token?.isNotEmpty ?? false)) {
      headers['Authorization'] = 'Bearer ${currentUser!.token}';
    }

    return headers;
  }

  // ================= REGISTER =================
  static Future<AppUser> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: _headers(withAuth: false),
      body: {"name": name, "email": email, "password": password},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final userJson = data['user'];
      final user = AppUser.fromJson(userJson);
      currentUser = user;
      return user;
    } else {
      throw Exception(data['message'] ?? "Gagal register");
    }
  }

  // ================= LOGIN =================
  static Future<AppUser> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: _headers(withAuth: false),
      body: {"email": email, "password": password},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final userJson = data['user'];
      final user = AppUser.fromJson(userJson);
      currentUser = user;
      return user;
    } else {
      throw Exception(data['message'] ?? "Email atau password salah");
    }
  }

  // ================= GET ALL PLACES =================
  static Future<List<dynamic>> getPlaces() async {
    final res = await http.get(
      Uri.parse("$baseUrl/places"),
      headers: _headers(withAuth: false),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal mengambil data places");
    }
  }

  // ================= GET DETAIL PLACE =================
  static Future<dynamic> getPlaceDetail(int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/places/$id"),
      headers: _headers(withAuth: false),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal mengambil detail place");
    }
  }

  // ================= DELETE PLACE =================
  static Future<bool> deletePlace(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/places/$id"),
      headers: _headers(withAuth: true),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Gagal menghapus tempat");
    }
  }

  // ================= CREATE PLACE =================
  static Future<bool> createPlace(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/places");

    final res = await http.post(
      url,
      headers: _headers(withAuth: true),
      body: body,
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return true;
    }

    return false;
  }

  // ================= UPDATE PLACE =================
  static Future<bool> updatePlace(String id, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/places/$id");

    final res = await http.put(
      url,
      headers: _headers(withAuth: true),
      body: body,
    );

    if (res.statusCode == 200) {
      return true;
    }
    return false;
  }

  // ================= GET PRODUCTS FOR PLACE =================
  static Future<List<dynamic>> getProductsByPlace(int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/places/$id/products"),
      headers: _headers(withAuth: false),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal mengambil produk");
    }
  }

  // ============= 🔥 BOOKING (BARU DITAMBAH) =============

  /// Ambil semua booking (dipakai ADMIN).
  /// Di Flutter: kalau role == user, filter sendiri berdasarkan userId.
  static Future<List<Booking>> getBookings() async {
    final res = await http.get(
      Uri.parse("$baseUrl/bookings"),
      headers: _headers(withAuth: false), // pakai true kalau sudah pakai token
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Booking.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil data booking (${res.statusCode})");
    }
  }

  /// (Opsional) Buat booking lewat service, biar BookingPage nggak POST sendiri.
  static Future<Booking> createBooking({
    required String userId,
    required String placeId,
    required String placeName,
    required DateTime dateTime,
    required int people,
    required String tableName,
    required List<String> productIds,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/bookings"),
      headers: {
        ..._headers(withAuth: false),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'place_id': placeId,
        'date_time': dateTime.toIso8601String(),
        'people': people,
        'table_name': tableName,
        'products': productIds,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      return Booking.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Gagal membuat booking');
    }
  }

  // ================= UPDATE PROFILE (NAMA + EMAIL) =================
  static Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update-profile"),
      headers: _headers(withAuth: false),
      body: {'user_id': userId.toString(), 'name': name, 'email': email},
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final userJson = data['user'];
      final updatedUser = AppUser.fromJson(userJson);
      currentUser = updatedUser;
      return updatedUser;
    } else {
      throw Exception(data['message'] ?? 'Gagal update profil');
    }
  }

  // ================= UPDATE PASSWORD =================
  static Future<void> updatePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update-password"),
      headers: _headers(withAuth: false),
      body: {
        'user_id': userId.toString(),
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Gagal update password');
    }
  }

  // ================= UPLOAD AVATAR =================
  static Future<AppUser> uploadAvatar({
    required int userId,
    required File file,
  }) async {
    final uri = Uri.parse("$baseUrl/upload-avatar");
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_headers(withAuth: false));
    request.fields['user_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final userJson = data['user'];
      final updatedUser = AppUser.fromJson(userJson);
      currentUser = updatedUser;
      return updatedUser;
    } else {
      throw Exception(data['message'] ?? 'Gagal upload avatar');
    }
  }
}

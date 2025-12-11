import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/user.dart';
import 'models/booking.dart';
import 'pages/auth/login_page.dart';
import 'pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // set default locale ke Indonesia
  Intl.defaultLocale = 'id_ID';

  // inisialisasi data tanggal untuk locale Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const CafeRestoApp());
}

class CafeRestoApp extends StatefulWidget {
  const CafeRestoApp({super.key});

  @override
  State<CafeRestoApp> createState() => _CafeRestoAppState();
}

class _CafeRestoAppState extends State<CafeRestoApp> {
  AppUser? _currentUser;
  final List<Booking> _bookings = [];

  void _login(AppUser user) => setState(() => _currentUser = user);
  void _logout() => setState(() => _currentUser = null);
  void _addBooking(Booking booking) => setState(() => _bookings.add(booking));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe & Resto Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF6F2EC),
      ),
      home: _currentUser == null
          ? LoginPage(onLoginSuccess: _login)
          : MainPage(
              user: _currentUser!,
              bookings: _bookings,
              onLogout: _logout,
              onAddBooking: _addBooking,
            ),
    );
  }
}

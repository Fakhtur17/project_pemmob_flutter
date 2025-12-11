import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import 'home_page.dart';
import 'cafe_page.dart';
import 'resto_page.dart';
import 'booking_history_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final AppUser user;
  final List<Booking> bookings;
  final VoidCallback onLogout;
  final Function(Booking) onAddBooking;

  const MainPage({
    super.key,
    required this.user,
    required this.bookings,
    required this.onLogout,
    required this.onAddBooking,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;
  late AppUser _currentUser;

  List<Booking> _bookings = [];
  bool _loadingBookings = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;

    // dari memori parent
    _bookings = List<Booking>.from(widget.bookings);

    // ambil dari API supaya sinkron database
    _loadBookings();
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.id != widget.user.id) {
      _currentUser = widget.user;
      _loadBookings();
    }

    if (oldWidget.bookings != widget.bookings) {
      _bookings = List<Booking>.from(widget.bookings);
    }
  }

  // 🔥 dipanggil saat profil berhasil di-update
  void _handleUserUpdated(AppUser updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });
    _loadBookings();
  }

  // 🔥 dipanggil saat booking dibuat
  void _handleAddBooking(Booking booking) {
    setState(() => _bookings.add(booking)); // update cepat
    _loadBookings(); // refresh API biar sinkron
  }

  // 🔥 ambil booking dari API
  Future<void> _loadBookings() async {
    setState(() => _loadingBookings = true);

    try {
      final all = await ApiService.getBookings();

      final filtered = _currentUser.role == 'admin'
          ? all
          : all.where((b) => b.userId == _currentUser.id.toString()).toList();

      if (!mounted) return;
      setState(() {
        _bookings = filtered;
        _loadingBookings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBookings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(user: _currentUser, onAddBooking: _handleAddBooking),

          CafePage(onAddBooking: _handleAddBooking, user: _currentUser),
          RestoPage(onAddBooking: _handleAddBooking, user: _currentUser),

          _loadingBookings
              ? const Center(child: CircularProgressIndicator())
              : BookingHistoryPage(
                  bookings: _bookings,
                  onBack: () => setState(() => _index = 0),
                  onCreateBooking: () => setState(() => _index = 1),
                ),

          ProfilePage(
            user: _currentUser,
            onLogout: widget.onLogout,
            onUserUpdated: _handleUserUpdated,
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_cafe_rounded),
            label: 'Cafe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_rounded),
            label: 'Resto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

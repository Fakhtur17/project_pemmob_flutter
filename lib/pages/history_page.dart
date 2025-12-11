// lib/pages/history_page.dart
import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'booking_history_page.dart';

class HistoryPage extends StatelessWidget {
  final List<Booking> bookings;

  const HistoryPage({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Booking')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BookingHistoryPage(bookings: bookings),
        ),
      ),
    );
  }
}

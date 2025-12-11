// lib/pages/booking_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/user.dart';

import '../models/booking.dart';
import '../models/place.dart';
import '../models/product.dart';

class BookingPage extends StatefulWidget {
  final Place place;
  final Function(Booking) onAddBooking;
  final List<Product> products;
  final AppUser user;

  const BookingPage({
    super.key,
    required this.place,
    required this.onAddBooking,
    required this.products,
    required this.user,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _peopleController = TextEditingController(text: '2');
  String _selectedTable = 'Meja 1';

  final _tables = ['Meja 1', 'Meja 2', 'Meja 3', 'Meja 4'];

  late List<Product> _products;
  List<Product> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _products = widget.products;
  }

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
    );
    if (result != null) setState(() => _selectedDate = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (result != null) setState(() => _selectedTime = result);
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan jam terlebih dulu')),
      );
      return;
    }

    final people = int.tryParse(_peopleController.text) ?? 1;
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final booking = Booking(
      id: const Uuid().v4(),
      userId: widget.user.id.toString(),
      placeId: widget.place.id,
      placeName: widget.place.name,
      dateTime: dt,
      people: people,
      tableName: _selectedTable,
      selectedProducts: _selectedProducts,
    );

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/bookings');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': booking.userId,
          'place_id': booking.placeId,
          'date_time': booking.dateTime.toIso8601String(),
          'people': booking.people,
          'table_name': booking.tableName,
          'products': booking.selectedProducts.map((e) => e.id).toList(),
        }),
      );

      if (response.statusCode == 201) {
        widget.onAddBooking(booking);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking berhasil dibuat')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal membuat booking')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final dateText = _selectedDate == null
        ? 'Pilih tanggal'
        : '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}';

    final timeText = _selectedTime == null
        ? 'Pilih jam'
        : _selectedTime!.format(context);

    final totalPrice = _selectedProducts.fold<int>(
      0,
      (sum, p) => sum + p.price,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F7),
      appBar: AppBar(
        title: Text(
          'Booking - ${widget.place.name}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // CARD INFO TEMPAT
                  _buildPlaceSummaryCard(scheme),

                  const SizedBox(height: 16),

                  // ALERT INFO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.brown.shade50,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.brown.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pastikan tanggal, jam, jumlah orang, meja, dan menu sudah sesuai sebelum konfirmasi booking.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD DETAIL BOOKING
                  _buildBookingDetailCard(
                    scheme: scheme,
                    dateText: dateText,
                    timeText: timeText,
                  ),

                  const SizedBox(height: 16),

                  // CARD PILIH MENU
                  _buildMenuCard(scheme, totalPrice),
                ],
              ),
            ),
          ),

          // FOOTER TOTAL + BUTTON
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Estimasi',
                          style: TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalPrice > 0
                              ? 'Rp $totalPrice'
                              : '- Pilih menu terlebih dahulu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: totalPrice > 0
                                ? Colors.brown.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.brown.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: _confirmBooking,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(
                        'Konfirmasi Booking',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============== WIDGET: CARD RINGKASAN TEMPAT ===============
  Widget _buildPlaceSummaryCard(ColorScheme scheme) {
    final place = widget.place;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black45),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 14,
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(place.openHours, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============== WIDGET: CARD DETAIL BOOKING ===============
  Widget _buildBookingDetailCard({
    required ColorScheme scheme,
    required String dateText,
    required String timeText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Booking',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // tanggal & jam dalam 1 row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  dateText,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jam',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  timeText,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // jumlah orang
            TextField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah orang',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // pilih meja
            DropdownButtonFormField<String>(
              value: _selectedTable,
              items: _tables
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedTable = val!),
              decoration: InputDecoration(
                labelText: 'Pilih meja',
                prefixIcon: const Icon(Icons.event_seat),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============== WIDGET: CARD PILIH MENU ===============
  Widget _buildMenuCard(ColorScheme scheme, int totalPrice) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Menu / Produk',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (_products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Belum ada menu untuk tempat ini.',
                  style: TextStyle(fontSize: 12),
                ),
              )
            else ...[
              const SizedBox(height: 6),
              ..._products.map((product) {
                final isSelected = _selectedProducts.contains(product);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Colors.brown.shade50
                        : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected
                          ? Colors.brown.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    activeColor: Colors.brown.shade600,
                    title: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      "Rp ${product.price}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedProducts.add(product);
                        } else {
                          _selectedProducts.remove(product);
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

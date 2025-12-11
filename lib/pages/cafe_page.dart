// lib/pages/cafe_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../models/place.dart';
import '../models/user.dart'; // ⬅️ TAMBAH INI
import 'place_detail_page.dart';
import '../services/api_service.dart';
import 'add_cafe_page.dart';
import 'edit_cafe_page.dart';

class CafePage extends StatefulWidget {
  final Function(Booking) onAddBooking;
  final AppUser user; // ⬅️ user yg sedang login

  const CafePage({
    super.key,
    required this.onAddBooking,
    required this.user, // ⬅️ wajib diisi waktu panggil CafePage
  });

  @override
  State<CafePage> createState() => _CafePageState();
}

class _CafePageState extends State<CafePage> {
  List<Place> _cafes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCafes();
  }

  Future<void> _fetchCafes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/places');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _cafes = data
            .map((e) => Place.fromJson(e))
            .where((place) => place.type == PlaceType.cafe)
            .toList();
      } else {
        _error = 'Gagal load data. Status: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    }

    setState(() {
      _loading = false;
    });
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Cafe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (ApiService.currentUser?.role == "admin") // hanya admin
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final refresh = await Navigator.of(context).push<bool>(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black.withOpacity(0.35),
                    pageBuilder: (_, __, ___) => const AddCafePage(),
                  ),
                );

                if (refresh == true) {
                  // reload list cafe
                  _fetchCafes();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _fetchCafes,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
            )
          : _cafes.isEmpty
          ? const Center(
              child: Text(
                'Belum ada cafe tersedia',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: _cafes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calculateCrossAxisCount(size.width),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 2.3, // sedikit lebih tinggi
                ),
                itemBuilder: (ctx, i) {
                  final place = _cafes[i];
                  return _CafeCard(
                    place: place,
                    onAddBooking: widget.onAddBooking,
                    onRefresh: _fetchCafes, // <-- penting
                    user: widget.user, // ⬅️ KIRIM user KE CARD
                  );
                },
              ),
            ),
    );
  }
}

class _CafeCard extends StatelessWidget {
  final Place place;
  final Function(Booking) onAddBooking;
  final VoidCallback? onRefresh; // <-- callback untuk refresh
  final AppUser user; // ⬅️ user yang login

  const _CafeCard({
    required this.place,
    required this.onAddBooking,
    this.onRefresh,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailPage(
                place: place,
                onAddBooking: onAddBooking,
                user: user, // ⬅️ INI YANG NGILANGIN ERROR
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header: gambar
            SizedBox(
              height: 90,
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
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 8,
                    bottom: 8,
                    child: Text(
                      'Cafe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.openHours,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (ApiService.currentUser?.role == "admin")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // EDIT
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final refresh = await Navigator.of(context)
                                    .push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierColor: Colors.black.withOpacity(
                                          0.35,
                                        ),
                                        pageBuilder: (_, __, ___) =>
                                            EditCafePage(place: place),
                                      ),
                                    );

                                if (refresh == true) {
                                  onRefresh?.call();
                                }
                              },
                            ),
                            // DELETE
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Hapus Cafe"),
                                    content: Text("Hapus '${place.name}' ?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Batal"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Hapus"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await ApiService.deletePlace(
                                    int.parse(place.id.toString()),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Berhasil dihapus"),
                                    ),
                                  );

                                  // refresh list di CafePage
                                  onRefresh?.call();
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

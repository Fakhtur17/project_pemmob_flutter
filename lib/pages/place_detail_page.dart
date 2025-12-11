// lib/pages/place_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../models/place.dart';
import '../models/product.dart';
import '../models/user.dart'; // 👈 IMPORT AppUser
import 'booking_page.dart';
import '../services/api_service.dart';

import 'package:url_launcher/url_launcher.dart';

class PlaceDetailPage extends StatefulWidget {
  final Place place;
  final Function(Booking) onAddBooking;
  final AppUser user; // 👈 user dari login

  const PlaceDetailPage({
    super.key,
    required this.place,
    required this.onAddBooking,
    required this.user,
  });

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  int _tabIndex = 0; // 0 = Detail, 1 = Menu
  bool _loadingProducts = true;
  List<Product> _products = [];

  // controller untuk form tambah/edit product
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _savingProduct = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ================== FETCH MENU ==================
  Future<void> _fetchProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final url = Uri.parse('$_baseUrl/api/places/${widget.place.id}/products');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _products = data.map((e) => Product.fromJson(e)).toList();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal load menu')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loadingProducts = false);
  }

  // ================== GOOGLE MAPS ==================
  Future<void> _openGoogleMaps(Place place) async {
    final query = Uri.encodeComponent('${place.name} ${place.address}');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
      );
    }
  }

  // ================== PRODUCT CRUD ==================

  Future<void> _showProductForm({Product? product}) async {
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _imageUrlController.text = product.imageUrl ?? '';
      _descriptionController.text = product.description ?? '';
    } else {
      _nameController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _descriptionController.clear();
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(product == null ? 'Tambah Menu' : 'Edit Menu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama menu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar (opsional)',
                        hintText: 'https://contoh.com/gambar.jpg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi menu (opsional)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _savingProduct ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: _savingProduct
                      ? null
                      : () async {
                          final name = _nameController.text.trim();
                          final priceText = _priceController.text.trim();

                          if (name.isEmpty || priceText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama dan harga tidak boleh kosong',
                                ),
                              ),
                            );
                            return;
                          }

                          final price = int.tryParse(priceText);
                          if (price == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Harga harus berupa angka'),
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => _savingProduct = true);
                          if (product == null) {
                            await _createProduct(name, price);
                          } else {
                            await _updateProduct(product, name, price);
                          }
                          setStateDialog(() => _savingProduct = false);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                  child: _savingProduct
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(product == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createProduct(String name, int price) async {
    try {
      final url = Uri.parse('$_baseUrl/api/products');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'place_id': widget.place.id,
          'name': name,
          'price': price,
          'image_url': _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu berhasil ditambahkan')),
        );
        await _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah menu (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateProduct(Product product, String name, int price) async {
    try {
      final url = Uri.parse('$_baseUrl/api/products/${product.id}');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'price': price,
          'image_url': _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu berhasil diupdate')));
        await _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update menu (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Menu'),
          content: Text('Yakin ingin menghapus menu "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      final url = Uri.parse('$_baseUrl/api/products/${product.id}');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Menu berhasil dihapus')));
        await _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus menu (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.local_cafe_rounded, color: Colors.brown),
    );
  }

  int _calculateProductCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final place = widget.place;

    // 👇 kalau mau patok ke user yang sedang login:
    // final bool isAdmin = widget.user.role == "admin";
    // atau kalau kamu tetap mau pakai ApiService.currentUser:
    final bool isAdmin = ApiService.currentUser?.role == "admin";

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [
          if (_tabIndex == 1 && isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showProductForm(),
              tooltip: 'Tambah Menu',
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              height: 220,
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
                    child: Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: _tabIndex == 0
                  ? _buildDetailTab(context, scheme, place)
                  : _loadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMenuTab(context, _products),
            ),
          ),

          // TOMBOL BOOKING
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        place: place,
                        onAddBooking: widget.onAddBooking,
                        products: _products,
                        user: widget.user, // 👈 INI YANG BENAR
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.event_seat_rounded),
                label: const Text('Booking Meja Sekarang'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            label: 'Detail',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  // ========= TAB DETAIL =========
  Widget _buildDetailTab(
    BuildContext context,
    ColorScheme scheme,
    Place place,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  place.address,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                'Jam buka: ${place.openHours}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                place.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openGoogleMaps(place),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.map_rounded,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
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
                              const SizedBox(height: 2),
                              Text(
                                place.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            place.description ??
                'Tempat yang nyaman untuk bersantai dan menikmati makanan atau minuman. '
                    'Kamu bisa melakukan reservasi meja terlebih dahulu agar tidak kehabisan tempat di jam sibuk.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // ========= TAB MENU =========
  Widget _buildMenuTab(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada menu untuk tempat ini.',
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    final bool isAdmin = ApiService.currentUser?.role == "admin";
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GridView.builder(
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateProductCrossAxisCount(size.width),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3 / 2.2,
        ),
        itemBuilder: (context, index) {
          final p = products[index];

          return Card(
            elevation: 2,
            color: Colors.brown.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                            ? Image.network(
                                p.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(child: _buildFallbackAvatar()),
                              )
                            : Container(child: _buildFallbackAvatar()),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.05),
                                Colors.black.withOpacity(0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 6,
                          right: 8,
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mulai dari',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rp ${p.price}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (p.description != null &&
                                  p.description!.isNotEmpty)
                                Text(
                                  p.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isAdmin)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showProductForm(product: p);
                              } else if (value == 'delete') {
                                _deleteProduct(p);
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert, size: 18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/api_service.dart';

class EditRestoPage extends StatefulWidget {
  final Place place;

  const EditRestoPage({super.key, required this.place});

  @override
  State<EditRestoPage> createState() => _EditRestoPageState();
}

class _EditRestoPageState extends State<EditRestoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController hoursController;
  late TextEditingController ratingController;
  late TextEditingController imageController;
  late TextEditingController descriptionController;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.place.name);
    addressController = TextEditingController(text: widget.place.address);
    hoursController = TextEditingController(text: widget.place.openHours);
    ratingController = TextEditingController(
      text: widget.place.rating.toString(),
    );
    imageController = TextEditingController(text: widget.place.imageUrl);
    descriptionController = TextEditingController(
      text: widget.place.description ?? "",
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    hoursController.dispose();
    ratingController.dispose();
    imageController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final body = {
      "name": nameController.text,
      "address": addressController.text,
      "open_hours": hoursController.text,
      "rating": ratingController.text,
      "image_url": imageController.text,
      "description": descriptionController.text,
      "type": "restaurant", // tetap restaurant
    };

    final result = await ApiService.updatePlace(widget.place.id, body);

    if (!mounted) return;
    setState(() => loading = false);

    if (result) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restoran berhasil diperbarui")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengedit restoran")));
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF7A6C6C),
      ),
      filled: true,
      fillColor: const Color(0xFFFFEBE4), // peach muda
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDBB8AA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDBB8AA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB27852), width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // transparan, supaya background-nya tetap halaman resto
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4D8), // card peach
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE
                        const Text(
                          "Edit Restoran",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B3A33),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // NAMA
                        TextFormField(
                          controller: nameController,
                          decoration: _fieldDecoration("Nama restoran"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Nama wajib diisi"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // ALAMAT
                        TextFormField(
                          controller: addressController,
                          decoration: _fieldDecoration("Alamat"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Alamat wajib diisi"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // JAM BUKA
                        TextFormField(
                          controller: hoursController,
                          decoration: _fieldDecoration(
                            "Jam buka",
                            hint: "10.00 - 22.00",
                          ),
                        ),
                        const SizedBox(height: 12),

                        // RATING
                        TextFormField(
                          controller: ratingController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _fieldDecoration(
                            "Rating",
                            hint: "Contoh: 4.7",
                          ),
                        ),
                        const SizedBox(height: 12),

                        // URL GAMBAR
                        TextFormField(
                          controller: imageController,
                          decoration: _fieldDecoration(
                            "URL gambar (opsional)",
                            hint: "https://contoh.com/gambar.jpg",
                          ),
                        ),
                        const SizedBox(height: 12),

                        // DESKRIPSI
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            "Deskripsi restoran (opsional)",
                            hint:
                                "Tema restoran, menu andalan, suasana keluarga, dll.",
                          ),
                        ),
                        const SizedBox(height: 24),

                        // BUTTON ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF8B6B5A),
                              ),
                              child: const Text("Batal"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: loading ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5A33),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      "Update",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

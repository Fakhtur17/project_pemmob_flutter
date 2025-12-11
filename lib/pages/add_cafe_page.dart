import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddCafePage extends StatefulWidget {
  const AddCafePage({super.key});

  @override
  State<AddCafePage> createState() => _AddCafePageState();
}

class _AddCafePageState extends State<AddCafePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final hoursController = TextEditingController();
  final ratingController = TextEditingController();
  final imageController = TextEditingController();
  final descriptionController = TextEditingController();

  bool loading = false;

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
      "type": "cafe",
    };

    final result = await ApiService.createPlace(body);

    if (!mounted) return;
    setState(() => loading = false);

    if (result) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cafe berhasil ditambahkan")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal menambah cafe")));
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
    // transparan → jadi popup dialog di atas halaman sebelumnya
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
                  color: const Color(0xFFFFE4D8),
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
                        const Text(
                          "Tambah Cafe",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B3A33),
                          ),
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: nameController,
                          decoration: _fieldDecoration("Nama cafe"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Nama wajib diisi"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: addressController,
                          decoration: _fieldDecoration("Alamat"),
                          validator: (v) => v == null || v.isEmpty
                              ? "Alamat wajib diisi"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: hoursController,
                          decoration: _fieldDecoration(
                            "Jam buka",
                            hint: "08.00 - 22.00",
                          ),
                        ),
                        const SizedBox(height: 12),

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

                        TextFormField(
                          controller: imageController,
                          decoration: _fieldDecoration(
                            "URL gambar (opsional)",
                            hint: "https://contoh.com/gambar.jpg",
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            "Deskripsi cafe (opsional)",
                            hint: "Suasana, menu favorit, keunggulan, dll.",
                          ),
                        ),
                        const SizedBox(height: 24),

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
                                      "Simpan",
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

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool loading = false;

  void _doRegister() async {
    if (_pass.text != _confirm.text) {
      setState(() => _error = "Password tidak sama");
      return;
    }

    setState(() => loading = true);

    try {
      final user = await ApiService.register(
        _name.text,
        _email.text,
        _pass.text,
      );

      Navigator.pop(context, user);
    } catch (e) {
      setState(() => _error = "Gagal mendaftar");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      appBar: AppBar(
        title: const Text("Daftar Akun", style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.brown.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Buat Akun Baru",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Isi data di bawah untuk membuat akun",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: "Nama",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Konfirmasi Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: loading ? null : _doRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Daftar",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

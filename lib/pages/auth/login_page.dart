import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final Function(AppUser) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool loading = false;

  void _doLogin() async {
    setState(() => loading = true);

    try {
      final user = await ApiService.login(_email.text, _password.text);
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() => _error = "Email atau password salah");
    }

    setState(() => loading = false);
  }

  void _goToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    if (result != null && result is AppUser) {
      setState(() {
        _email.text = result.email;
        _error = "Akun berhasil dibuat, silakan login.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
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
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Masuk menggunakan akun Anda",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

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
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
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
                        onPressed: loading ? null : _doLogin,
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
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _goToRegister,
                      child: const Text(
                        "Belum punya akun? Daftar",
                        style: TextStyle(fontSize: 14),
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

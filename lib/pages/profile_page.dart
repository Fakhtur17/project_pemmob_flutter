// lib/pages/profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  // callback ke MainPage kalau user berhasil di-update
  final ValueChanged<AppUser> onUserUpdated;

  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onUserUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  String? _avatarPath;

  bool _isEditing = false;
  bool _isSaving = false;

  File? _avatarFile;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = widget.user.name;
    _email = widget.user.email;
    _avatarPath = widget.user.avatar;

    _nameController.text = _name;
    _emailController.text = _email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================== PICK + UPLOAD AVATAR ==================
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() {
      _avatarFile = File(picked.path);
      _isSaving = true;
    });

    try {
      final updatedUser = await ApiService.uploadAvatar(
        userId: widget.user.id,
        file: _avatarFile!,
      );

      setState(() {
        _isSaving = false;
        _name = updatedUser.name;
        _email = updatedUser.email;
        _avatarPath = updatedUser.avatar;
      });

      widget.onUserUpdated(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload avatar: $e')));
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _nameController.text = _name;
        _emailController.text = _email;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  // ================== SAVE PROFIL (NAMA + EMAIL + PASSWORD) ==================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    try {
      final updatedUserFromApi = await ApiService.updateProfile(
        userId: widget.user.id,
        name: newName,
        email: newEmail,
      );

      if (currentPassword.isNotEmpty || newPassword.isNotEmpty) {
        await ApiService.updatePassword(
          userId: widget.user.id,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }

      setState(() {
        _name = updatedUserFromApi.name;
        _email = updatedUserFromApi.email;
        _avatarPath = updatedUserFromApi.avatar;
        _isSaving = false;
        _isEditing = false;
      });

      widget.onUserUpdated(updatedUserFromApi);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentPassword.isNotEmpty || newPassword.isNotEmpty
                  ? 'Profil & password berhasil diperbarui'
                  : 'Profil berhasil diperbarui',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade600,

        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: Colors.white,
            ),
            tooltip: _isEditing ? 'Batal edit' : 'Edit profil',
            onPressed: _isSaving ? null : _toggleEdit,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(scheme),
                const SizedBox(height: 16),
                _isEditing ? _buildEditForm(scheme) : _buildStaticInfo(scheme),
                const SizedBox(height: 20),
                _buildLogoutButton(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== HEADER (FOTO + NAMA) ==================
  Widget _buildProfileHeader(ColorScheme scheme) {
    String? avatarUrl;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      avatarUrl = "http://127.0.0.1:8000/storage/$_avatarPath";
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (avatarUrl != null
                            ? NetworkImage(avatarUrl) as ImageProvider
                            : null),
                  child: _avatarFile == null && avatarUrl == null
                      ? Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _isSaving ? null : _pickAvatar,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: Colors.green,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Akun Terdaftar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== MODE LIHAT (STATIC) ==================
  Widget _buildStaticInfo(ColorScheme scheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person_outline_rounded, color: scheme.primary),
            title: const Text('Nama'),
            subtitle: Text(_name),
          ),
          const Divider(height: 0),
          ListTile(
            leading: Icon(Icons.email_outlined, color: scheme.primary),
            title: const Text('Email'),
            subtitle: Text(_email),
          ),
          const Divider(height: 0),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Tentang aplikasi'),
            subtitle: Text(
              'Aplikasi sederhana untuk booking meja cafe dan restoran.',
            ),
          ),
        ],
      ),
    );
  }

  // ================== MODE EDIT (FORM) ==================
  Widget _buildEditForm(ColorScheme scheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (val.trim().length < 3) {
                    return 'Nama terlalu pendek';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!val.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Ubah Password (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Password saat ini',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Password baru',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi password baru',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (val) {
                  if (_newPasswordController.text.isNotEmpty ||
                      _confirmPasswordController.text.isNotEmpty ||
                      _currentPasswordController.text.isNotEmpty) {
                    if (_currentPasswordController.text.isEmpty) {
                      return 'Masukkan password saat ini untuk mengubah password';
                    }
                    if (_newPasswordController.text.length < 6) {
                      return 'Password baru minimal 6 karakter';
                    }
                    if (val != _newPasswordController.text) {
                      return 'Konfirmasi password tidak sama';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _toggleEdit,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== LOGOUT ==================
  Widget _buildLogoutButton(ColorScheme scheme) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: widget.onLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Logout'),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ),
      ),
    );
  }
}

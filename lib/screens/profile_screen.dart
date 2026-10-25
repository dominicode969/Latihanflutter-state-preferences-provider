import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _favoriteController = TextEditingController();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _controllersInitialized = false;

  // Latihan 5: simulasi daftar email yang sudah terdaftar
  static const List<String> _seedEmails = [
    'admin@example.com',
    'test@example.com',
  ];

  // Latihan 5: pola karakter berbahaya (mis. <script>)
  static final RegExp _dangerousPattern = RegExp(
    r'[<>{}]|javascript:',
    caseSensitive: false,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;

    final provider = UserProvider.read(context);
    _nameController = TextEditingController(text: provider.user.name);
    _emailController = TextEditingController(text: provider.user.email);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = UserProvider.read(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Latihan 5(b): tolak nama yang mengandung karakter berbahaya
    if (_dangerousPattern.hasMatch(name)) {
      _showMessage(
        'Nama mengandung karakter yang tidak diperbolehkan',
        isError: true,
      );
      return;
    }

    // Latihan 5(a): simulasi pengecekan email yang sudah digunakan
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = (prefs.getString('user_email') ?? '').toLowerCase();
    final usedEmails = prefs.getStringList('used_emails') ?? _seedEmails;
    final isTaken =
        email.toLowerCase() != currentEmail &&
        usedEmails.contains(email.toLowerCase());

    if (!mounted) return;
    if (isTaken) {
      _showMessage('Email sudah digunakan oleh akun lain', isError: true);
      return;
    }

    // Simpan profil
    final updatedUser = provider.user.copyWith(
      name: name,
      email: email,
      isLoggedIn: true,
    );
    await provider.updateUser(updatedUser);
    await prefs.setStringList('used_emails', [
      ...usedEmails.where((e) => e != currentEmail),
      email.toLowerCase(),
    ]);

    if (!mounted) return;
    _showMessage('Profil berhasil disimpan');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              UserProvider.read(context).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Latihan 3: tambah item favorit
  void _addFavorite() {
    final item = _favoriteController.text.trim();
    if (item.isEmpty) return;

    if (_dangerousPattern.hasMatch(item)) {
      _showMessage(
        'Item mengandung karakter yang tidak diperbolehkan',
        isError: true,
      );
      return;
    }
    final provider = UserProvider.read(context);
    if (provider.favorites.contains(item)) {
      _showMessage('"$item" sudah ada di daftar favorit', isError: true);
      return;
    }
    provider.addFavorite(item);
    _favoriteController.clear();
  }

  // Latihan 3: kartu daftar favorit
  Widget _buildFavoritesCard(UserProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink),
                SizedBox(width: 8),
                Text(
                  'Daftar Favorit (Hobi)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _favoriteController,
                    decoration: const InputDecoration(
                      hintText: 'Tambah hobi baru',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addFavorite(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addFavorite,
                  icon: const Icon(Icons.add),
                  tooltip: 'Tambah',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Belum ada favorit',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: provider.favorites
                    .map(
                      (item) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(item),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Hapus',
                          onPressed: () =>
                              UserProvider.read(context).removeFavorite(item),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Nama',
                            prefixIcon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daftar favorit (Latihan 3)
                    _buildFavoritesCard(provider),
                    const SizedBox(height: 16),

                    // Catatan keamanan
                    Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.amber[800]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Catatan Keamanan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Data disimpan di SharedPreferences (plaintext). '
                              'Jangan simpan password atau data sensitif di sini. '
                              'Gunakan secure storage untuk data sensitif.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

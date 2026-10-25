import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// InheritedWidget yang menyediakan state user ke seluruh subtree.
class UserProvider extends InheritedWidget {
  final User user;
  final bool isLoading;
  final bool isDarkMode; // Latihan 1
  final int visitCount; // Latihan 2
  final List<String> favorites; // Latihan 3
  final Future<void> Function(User) updateUser;
  final VoidCallback logout;
  final VoidCallback toggleTheme; // Latihan 1
  final void Function(String) addFavorite; // Latihan 3
  final void Function(String) removeFavorite; // Latihan 3

  const UserProvider({
    super.key,
    required this.user,
    required this.isLoading,
    required this.isDarkMode,
    required this.visitCount,
    required this.favorites,
    required this.updateUser,
    required this.logout,
    required this.toggleTheme,
    required this.addFavorite,
    required this.removeFavorite,
    required super.child,
  });

  /// Dipakai di build(): mendaftarkan context sebagai dependent,
  /// sehingga widget di-rebuild saat data berubah.
  static UserProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  /// Dipakai di event handler (onPressed, dll): tidak mendaftarkan dependent.
  static UserProvider read(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return oldWidget.user != user ||
        oldWidget.isLoading != isLoading ||
        oldWidget.isDarkMode != isDarkMode ||
        oldWidget.visitCount != visitCount ||
        oldWidget.favorites != favorites;
  }
}

// StatefulWidget yang membungkus InheritedWidget
class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Memuat data dari SharedPreferences
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false; // Latihan 1
    final favorites = prefs.getStringList('favorites') ?? []; // Latihan 3

    // Latihan 2: tambah counter kunjungan setiap aplikasi dibuka
    final visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visitCount);

    if (!mounted) return;
    setState(() {
      _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
      _isDarkMode = isDarkMode;
      _visitCount = visitCount;
      _favorites = favorites;
      _isLoading = false;
    });
  }

  // Menyimpan data user ke SharedPreferences
  Future<void> _updateUser(User newUser) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    if (!mounted) return;
    setState(() {
      _user = newUser;
      _isLoading = false;
    });
  }

  // Logout: hapus nama dan status login (email tetap)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    if (!mounted) return;
    setState(() {
      _user = _user.copyWith(name: '', isLoggedIn: false);
    });
  }

  // Latihan 1: ganti tema dan simpan preferensinya
  Future<void> _toggleTheme() async {
    final newValue = !_isDarkMode;
    setState(() {
      _isDarkMode = newValue;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', newValue);
  }

  // Latihan 3: tambah item favorit
  Future<void> _addFavorite(String item) async {
    final trimmed = item.trim();
    if (trimmed.isEmpty || _favorites.contains(trimmed)) return;

    final updated = [..._favorites, trimmed];
    setState(() {
      _favorites = updated;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);
  }

  // Latihan 3: hapus item favorit
  Future<void> _removeFavorite(String item) async {
    final updated = _favorites.where((e) => e != item).toList();
    setState(() {
      _favorites = updated;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);
  }

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      user: _user,
      isLoading: _isLoading,
      isDarkMode: _isDarkMode,
      visitCount: _visitCount,
      favorites: _favorites,
      updateUser: _updateUser,
      logout: _logout,
      toggleTheme: _toggleTheme,
      addFavorite: _addFavorite,
      removeFavorite: _removeFavorite,
      child: widget.child,
    );
  }
}

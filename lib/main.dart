import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view_model/auth_provider.dart';
import 'view_model/halaman_utama_provider.dart';
import 'view/halaman_login.dart';
import 'view/halaman_utama.dart';


void main() {
  runApp(
    // Mendaftarkan Provider agar bisa digunakan di seluruh aplikasi
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HalamanUtamaProvider()),
      ],
      child: const AppSekolah(),
    ),
  );
}

class AppSekolah extends StatefulWidget {
  const AppSekolah({super.key});

  @override
  State<AppSekolah> createState() => _AppSekolahState();
}

class _AppSekolahState extends State<AppSekolah> {
  @override
  void initState() {
    super.initState();
    // Menjalankan pengecekan sesi otomatis saat aplikasi pertama kali dibuka
    // Ini adalah fitur "Ingat Saya" yang Anda inginkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().cekSesiOtomatis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pelanggaran Sekolah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Konsumen (Consumer) memantau status login di AuthProvider
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Jika data user ada (sudah login), langsung ke Halaman Utama
          if (auth.user != null) {
            return const HalamanUtama();
          }
          // Jika data user kosong, tampilkan Halaman Login
          return const HalamanLogin();
        },
      ),
    );
  }
}
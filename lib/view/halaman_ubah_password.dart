import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/ubah_password_provider.dart';

class HalamanUbahPassword extends StatefulWidget {
  const HalamanUbahPassword({super.key});

  @override
  State<HalamanUbahPassword> createState() => _HalamanUbahPasswordState();
}

class _HalamanUbahPasswordState extends State<HalamanUbahPassword> {
  final TextEditingController _passwordLamaController = TextEditingController();
  final TextEditingController _passwordBaruController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();

  bool _showPasswordLama = false;
  bool _showPasswordBaru = false;
  bool _showKonfirmasiPassword = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authWatch = context.watch<AuthProvider>();
    final ubahPasswordWatch = context.watch<UbahPasswordProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          "Ubah Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ICON HEADER ---
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.indigo.shade100,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 55,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- JUDUL & DESKRIPSI ---
                const Center(
                  child: Text(
                    "Keamanan Akun",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Perbarui password Anda secara berkala untuk menjaga keamanan akun",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // --- PESAN ERROR ---
                if (ubahPasswordWatch.pesanError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ubahPasswordWatch.pesanError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- INPUT PASSWORD LAMA ---
                const Text(
                  "Password Lama",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordLamaController,
                  obscureText: !_showPasswordLama,
                  decoration: InputDecoration(
                    hintText: "Masukkan password lama Anda",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPasswordLama ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPasswordLama = !_showPasswordLama;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.indigo.shade900, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password lama harus diisi";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- INPUT PASSWORD BARU ---
                const Text(
                  "Password Baru",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordBaruController,
                  obscureText: !_showPasswordBaru,
                  decoration: InputDecoration(
                    hintText: "Masukkan password baru (minimal 6 karakter)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPasswordBaru ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPasswordBaru = !_showPasswordBaru;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.indigo.shade900, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password baru harus diisi";
                    }
                    if (value.length < 6) {
                      return "Password minimal 6 karakter";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- INPUT KONFIRMASI PASSWORD ---
                const Text(
                  "Konfirmasi Password Baru",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _konfirmasiPasswordController,
                  obscureText: !_showKonfirmasiPassword,
                  decoration: InputDecoration(
                    hintText: "Ulangi password baru Anda",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showKonfirmasiPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _showKonfirmasiPassword = !_showKonfirmasiPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.indigo.shade900, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Konfirmasi password harus diisi";
                    }
                    if (value != _passwordBaruController.text) {
                      return "Password tidak cocok";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // --- TOMBOL SIMPAN ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: ubahPasswordWatch.sedangLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            // Clear error message sebelum request
                            context.read<UbahPasswordProvider>().resetPesanError();

                            final token = authWatch.user?.token ?? "";
                            final sukses = await context.read<UbahPasswordProvider>().ubahPassword(
                              token,
                              _passwordLamaController.text,
                              _passwordBaruController.text,
                              _konfirmasiPasswordController.text,
                            );

                            if (sukses && context.mounted) {
                              // Clear controllers
                              _passwordLamaController.clear();
                              _passwordBaruController.clear();
                              _konfirmasiPasswordController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Password berhasil diubah"),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // Kembali ke halaman utama setelah 1 detik
                              Future.delayed(const Duration(seconds: 1), () {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: ubahPasswordWatch.sedangLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "UBAH PASSWORD",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- TOMBOL BATAL ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "BATAL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

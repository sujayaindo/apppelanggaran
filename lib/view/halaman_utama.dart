import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/halaman_utama_provider.dart';
import '../model/user_model.dart';
import 'halaman_input_pelanggaran.dart';
import 'halaman_catatan_pelanggaran.dart';
import 'halaman_ubah_password.dart';

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () {
      if (mounted) {
        final token = context.read<AuthProvider>().user?.token ?? "";
        context.read<HalamanUtamaProvider>().ambilStatistik(token);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().cekSesiAktif();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authWatch = context.watch<AuthProvider>();
    final homeWatch = context.watch<HalamanUtamaProvider>();
    final user = authWatch.user;
    final String peran = user?.peran.toLowerCase() ?? "";
    final bool canInput = peran == 'guru' || peran == 'pegawai' || peran == 'pks';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            bool isLandscape = orientation == Orientation.landscape;

            // Konten Utama Aplikasi
            Widget mainContent = Column(
              children: [
                // 1. HEADER
                _buildHeader(user), 
                
                // 2. LAYANAN & TOMBOL MENU
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Layanan SIMPEL",
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridButton(
                              title: "Input Pelanggaran",
                              icon: Icons.add_moderator_rounded,
                              color: Colors.indigo.shade900,
                              isActive: canInput,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HalamanInputPelanggaran()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGridButton(
                              title: "Catatan Pelanggaran",
                              icon: Icons.assignment_rounded,
                              color: Colors.blue.shade700,
                              isActive: true,
                              onTap: () {
                                // Navigasi Riwayat Lengkap
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HalamanCatatanPelanggaran()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Tren Pelanggaran Hari Ini",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // 3. AREA STATISTIK
                if (isLandscape)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStatistikList(homeWatch),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () {
                        final token = context.read<AuthProvider>().user?.token ?? "";
                        return context.read<HalamanUtamaProvider>().ambilStatistik(token);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _buildStatistikList(homeWatch),
                      ),
                    ),
                  ),
              ],
            );

            return isLandscape 
                ? SingleChildScrollView(child: mainContent) 
                : mainContent;
          },
        ),
      ),
    );
  }

  // --- KOMPONEN HEADER ---
  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            // PERBAIKAN: withOpacity -> withValues
            color: Colors.indigo.withValues(alpha: 0.3), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Selamat Datang,", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  user?.nama ?? "Pengguna",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // PERBAIKAN: withOpacity -> withValues
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                    user?.peran.toUpperCase() ?? "-",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildHeaderIcon(
                Icons.settings_outlined,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HalamanUbahPassword()),
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildHeaderIcon(
                Icons.logout_rounded, 
                () => context.read<AuthProvider>().logout(), 
                isDanger: true
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN TOMBOL GRID ---
  Widget _buildGridButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isActive ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isActive ? [
              BoxShadow(
                // PERBAIKAN: withOpacity -> withValues
                color: color.withValues(alpha: 0.3), 
                blurRadius: 12, 
                offset: const Offset(0, 6)
              )
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- KOMPONEN IKON HEADER ---
  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDanger 
              // PERBAIKAN: withOpacity -> withValues
              ? Colors.red.withValues(alpha: 0.2) 
              : Colors.white.withValues(alpha: 0.1), 
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: isDanger ? Colors.redAccent.shade100 : Colors.white, size: 22),
      ),
    );
  }

  // --- KOMPONEN LIST STATISTIK ---
  Widget _buildStatistikList(HalamanUtamaProvider provider) {
    if (provider.loadingStatistik) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }
    if (provider.statistikJenis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(35),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(25), 
          border: Border.all(color: Colors.grey.shade200)
        ),
        child: const Column(
          children: [
            Icon(Icons.analytics_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 12),
            Text("Belum ada data hari ini.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.statistikJenis.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8, 
      ),
      itemBuilder: (context, index) {
        final item = provider.statistikJenis[index];
        final List<Color> labelColors = [Colors.indigo, Colors.orange, Colors.red, Colors.teal];
        final Color themeColor = labelColors[index % labelColors.length];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['jenis'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${item['jumlah']} Kasus",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
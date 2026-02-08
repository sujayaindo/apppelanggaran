import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/input_pelanggaran_provider.dart';
import '../provider/halaman_utama_provider.dart';

class HalamanInputPelanggaran extends StatefulWidget {
  const HalamanInputPelanggaran({super.key});

  @override
  State<HalamanInputPelanggaran> createState() => _HalamanInputPelanggaranState();
}

class _HalamanInputPelanggaranState extends State<HalamanInputPelanggaran> {
  final TextEditingController _searchSiswaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().user?.token ?? "";
      final prov = context.read<InputPelanggaranProvider>();
      
      prov.ambilMasterPelanggaran(token);
      prov.ambilRiwayatHariIni(token);
    });
  }

  @override
  void dispose() {
    _searchSiswaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<InputPelanggaranProvider>();
    final token = auth.user?.token ?? "";
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          // Agar keyboard tidak memicu overflow saat muncul
          resizeToAvoidBottomInset: true, 
          appBar: AppBar(
            title: const Text("Catat Pelanggaran", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.indigo.shade900,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(icon: Icon(Icons.edit_note), text: "Input"),
                Tab(icon: Icon(Icons.history), text: "Riwayat"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildTabInput(prov, token),
              _buildTabRiwayat(prov, token),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: FORM INPUT ---
  Widget _buildTabInput(InputPelanggaranProvider prov, String token) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Cari Siswa", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchSiswaController,
            decoration: InputDecoration(
              hintText: "Ketik Nama atau NIS...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) => prov.cariSiswa(token, val),
          ),
          
          if (prov.daftarSiswa.isNotEmpty && prov.siswaTerpilih == null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prov.daftarSiswa.length,
                itemBuilder: (context, index) {
                  final s = prov.daftarSiswa[index];
                  return ListTile(
                    title: Text(s['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${s['nis']} • ${s['nama_kelas']}"),
                    onTap: () {
                      prov.pilihSiswa(s);
                      _searchSiswaController.text = s['nama'];
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),

          if (prov.siswaTerpilih != null)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Terpilih: ${prov.siswaTerpilih!['nama']}", 
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      prov.pilihSiswa(null);
                      _searchSiswaController.clear();
                    },
                  )
                ],
              ),
            ),

          const SizedBox(height: 24),
          const Text("Pilih Jenis Pelanggaran", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              onExpansionChanged: (exp) { if(exp) FocusScope.of(context).unfocus(); },
              leading: Icon(Icons.list_alt_rounded, color: Colors.indigo.shade900),
              title: Text(
                prov.selectedPelanggaran.isEmpty 
                    ? "Klik untuk memilih..." 
                    : "${prov.selectedPelanggaran.length} Dipilih",
                style: TextStyle(fontSize: 14, 
                  color: prov.selectedPelanggaran.isEmpty ? Colors.grey : Colors.black),
              ),
              children: [
                SizedBox(
                  height: 250, 
                  child: prov.loadingMaster
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: prov.masterPelanggaran.length,
                          itemBuilder: (context, index) {
                            final item = prov.masterPelanggaran[index];
                            final int idInt = int.parse(item['id'].toString());
                            return CheckboxListTile(
                              activeColor: Colors.indigo.shade900,
                              title: Text(item['nama_pelanggaran'], style: const TextStyle(fontSize: 13)),
                              subtitle: Text("${item['kategori']} • ${item['poin']} Poin", 
                                style: const TextStyle(fontSize: 11)),
                              value: prov.selectedPelanggaran.contains(idInt),
                              onChanged: (bool? value) => prov.togglePelanggaran(idInt),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text("Bukti Foto", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          Center(
            child: Column(
              children: [
                if (prov.fotoBukti != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black,
                          constraints: const BoxConstraints(maxHeight: 400, minHeight: 200, minWidth: double.infinity),
                          child: kIsWeb 
                            ? Image.memory(prov.webImage!, fit: BoxFit.contain)
                            : Image.file(File(prov.fotoBukti!.path), fit: BoxFit.contain),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => prov.hapusFoto(),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text("Hapus & Ambil Ulang", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: () => _pilihSumberFoto(context, prov),
                    child: Container(
                      height: 150, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Ambil Foto Bukti", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: prov.isSaving ? null : () async {
                final sukses = await prov.simpanPelanggaran(token);
                if (!mounted) return; 
                if (sukses) {
                  context.read<HalamanUtamaProvider>().ambilStatistik(token);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil disimpan!")));
                  _searchSiswaController.clear();
                }
              },
              child: prov.isSaving 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("SIMPAN PELANGGARAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: RIWAYAT HARI INI (FIX: VERTICAL BUTTONS & NO OVERFLOW) ---
  Widget _buildTabRiwayat(InputPelanggaranProvider prov, String token) {
    if (prov.loadingRiwayat) return const Center(child: CircularProgressIndicator());
    if (prov.riwayatHariIni.isEmpty) return const Center(child: Text("Belum ada catatan hari ini."));

    return RefreshIndicator(
      onRefresh: () => prov.ambilRiwayatHariIni(token),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: prov.riwayatHariIni.length,
        itemBuilder: (context, index) {
          final item = prov.riwayatHariIni[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16), // Padding internal kartu
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FOTO PROFIL / INISIAL
                  CircleAvatar(
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                    child: Text((item['nama_siswa'] ?? "S")[0].toUpperCase(), 
                      style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),

                  // 2. KONTEN TEKS (DI TENGAH)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Siswa (Utuh)
                        Text(
                          item['nama_siswa'] ?? "Siswa", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        // Badge Kelas
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Kelas: ${item['nama_kelas'] ?? '-'}", 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Jenis Pelanggaran (Utuh)
                        Text(
                          item['nama_pelanggaran'] ?? "-", 
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        // Nama Pencatat (Utuh)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.person_pin_outlined, size: 14, color: Colors.grey),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Dicatat oleh: ${item['nama_pencatat'] ?? '-'}", 
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 3. TOMBOL AKSI (VERTIKAL DI KANAN)
                  Column(
                    children: [
                      if (item['url_bukti_foto'] != null && item['url_bukti_foto'] != "")
                        IconButton(
                          icon: const Icon(Icons.image_outlined, color: Colors.blue, size: 24),
                          onPressed: () => _lihatFoto(context, item['url_bukti_foto']),
                        ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                        onPressed: () => _konfirmasiHapus(context, prov, token, item['id'].toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- FUNGSI HELPER ---
  void _pilihSumberFoto(BuildContext context, InputPelanggaranProvider prov) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.camera), title: const Text("Kamera"), onTap: () { Navigator.pop(context); prov.ambilFoto(true); }),
      ListTile(leading: const Icon(Icons.photo_library), title: const Text("Galeri"), onTap: () { Navigator.pop(context); prov.ambilFoto(false); }),
    ])));
  }

  void _lihatFoto(BuildContext context, String fileId) {
    showDialog(context: context, builder: (_) => Dialog(child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppBar(title: const Text("Bukti Foto"), automaticallyImplyLeading: false, backgroundColor: Colors.indigo.shade900, foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
      Image.network("https://drive.google.com/thumbnail?id=$fileId&sz=w1000", loadingBuilder: (ctx, child, progress) => progress == null ? child : const Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator())),
    ])));
  }

  void _konfirmasiHapus(BuildContext context, InputPelanggaranProvider prov, String token, String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Hapus Data?"), content: const Text("Tindakan ini tidak dapat dibatalkan."), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
      TextButton(onPressed: () async { 
        final nav = Navigator.of(ctx); 
        // 1. Jalankan fungsi hapus
        final bool sukses = await prov.hapusPelanggaran(token, id);
        
        nav.pop(); // Tutup dialog

        if (sukses) {
          // 2. REFRESH STATISTIK DI HALAMAN UTAMA
          if (context.mounted) {
            context.read<HalamanUtamaProvider>().ambilStatistik(token);
          }
          
          // 3. Tampilkan notifikasi
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Data berhasil dihapus"))
            );
          }
        }
      }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
    ]));
  }
}
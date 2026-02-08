import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../view_model/auth_provider.dart';
import '../view_model/input_pelanggaran_provider.dart';
import '../view_model/halaman_utama_provider.dart';

import 'package:flutter/foundation.dart' show kIsWeb; // Tambahkan ini


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
    // Menjalankan pengambilan data tepat setelah frame pertama dirender
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Catat Pelanggaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo.shade900,
          foregroundColor: Colors.white,
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
          
          // Hasil Pencarian Siswa
          if (prov.daftarSiswa.isNotEmpty)
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
                      prov.daftarSiswa.clear();
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),

          if (prov.siswaTerpilih != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("Terpilih: ${prov.siswaTerpilih!['nama']}", 
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),

          const SizedBox(height: 24),
          const Text("Pilih Jenis Pelanggaran", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // --- COMBO LIST (EXPANSION TILE) ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: Icon(Icons.list_alt_rounded, color: Colors.indigo.shade900),
              title: Text(
                prov.selectedPelanggaran.isEmpty 
                    ? "Klik untuk memilih..." 
                    : "${prov.selectedPelanggaran.length} Dipilih",
                style: TextStyle(
                  fontSize: 14, 
                  color: prov.selectedPelanggaran.isEmpty ? Colors.grey : Colors.black,
                ),
              ),
              children: [
                SizedBox(
                  height: 250, // Tinggi tetap agar bisa di-scroll dalam list
                  child: prov.loadingMaster
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: prov.masterPelanggaran.length,
                          itemBuilder: (context, index) {
                            final item = prov.masterPelanggaran[index];
                            final bool isChecked = prov.selectedPelanggaran.contains(item['id']);
                            return CheckboxListTile(
                              activeColor: Colors.indigo.shade900,
                              title: Text(item['nama_pelanggaran'], style: const TextStyle(fontSize: 13)),
                              subtitle: Text("${item['kategori']} • ${item['poin']} Poin", style: const TextStyle(fontSize: 11)),
                              value: isChecked,
                              onChanged: (bool? value) => prov.togglePelanggaran(item['id']),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb 
                      ? Image.network(
                          prov.fotoBukti!.path, // Di Web, path berisi blob URL yang bisa dibaca Image.network
                          height: 150, 
                          width: 250, 
                          fit: BoxFit.cover
                        )
                      : Image.file(
                          File(prov.fotoBukti!.path), 
                          height: 150, 
                          width: 250, 
                          fit: BoxFit.cover
                        ),
                  )
                else
                  Container(
                    height: 150, width: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _pilihSumberFoto(context, prov),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Ambil Foto Bukti"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: prov.isSaving ? null : () async {
                // 1. Jalankan fungsi asinkron
                final sukses = await prov.simpanPelanggaran(token);

                // 2. Gunakan 'mounted' (milik State), bukan 'context.mounted'
                // Letakkan tepat di bawah await secara mandiri
                if (!mounted) return; 

                // 3. Logika UI setelah dipastikan masih terpasang
                if (sukses) {
                  context.read<HalamanUtamaProvider>().ambilStatistik(token);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Data berhasil disimpan!"))
                  );
                  _searchSiswaController.clear();
                }
              },
              child: prov.isSaving 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("SIMPAN PELANGGARAN", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: RIWAYAT HARI INI ---
  Widget _buildTabRiwayat(InputPelanggaranProvider prov, String token) {
    if (prov.loadingRiwayat) return const Center(child: CircularProgressIndicator());
    if (prov.riwayatHariIni.isEmpty) return const Center(child: Text("Belum ada catatan hari ini."));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: prov.riwayatHariIni.length,
      itemBuilder: (context, index) {
        final item = prov.riwayatHariIni[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(item['nama_siswa'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['nama_pelanggaran']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item['url_bukti_foto'] != null && item['url_bukti_foto'] != "")
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.blue),
                    onPressed: () => _lihatFoto(context, item['url_bukti_foto']),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _konfirmasiHapus(context, prov, token, item['id'].toString()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI HELPER ---
  void _pilihSumberFoto(BuildContext context, InputPelanggaranProvider prov) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera), title: const Text("Kamera"), onTap: () { Navigator.pop(context); prov.ambilFoto(true); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text("Galeri"), onTap: () { Navigator.pop(context); prov.ambilFoto(false); }),
          ],
        ),
      ),
    );
  }

  void _lihatFoto(BuildContext context, String fileId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text("Bukti Foto"), 
              automaticallyImplyLeading: false, 
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close), 
                  onPressed: () => Navigator.pop(context)
                )
              ],
            ),
            // Menggunakan loadingBuilder sebagai pengganti placeholder
            Image.network(
              "https://drive.google.com/thumbnail?id=$fileId&sz=w1000",
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child; // Foto selesai dimuat
                return const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("Foto tidak tersedia")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _konfirmasiHapus(BuildContext context, InputPelanggaranProvider prov, String token, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Data?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(onPressed: () async {
            final nav = Navigator.of(ctx);
            await prov.hapusPelanggaran(token, id);
            nav.pop();
          }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
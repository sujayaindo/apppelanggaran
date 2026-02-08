import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/catatan_pelanggaran_provider.dart';
import '../provider/auth_provider.dart';
import 'halaman_detail_pelanggaran.dart';

class HalamanCatatanPelanggaran extends StatefulWidget {
  const HalamanCatatanPelanggaran({super.key});

  @override
  State<HalamanCatatanPelanggaran> createState() =>
      _HalamanCatatanPelanggaranState();
}

class _HalamanCatatanPelanggaranState extends State<HalamanCatatanPelanggaran> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ambilData();
    });
  }

  void _ambilData() {
    final token = context.read<AuthProvider>().user?.token ?? "";
    context.read<CatatanPelanggaranProvider>().ambilData(token);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatatanPelanggaranProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Pelanggaran'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BAGIAN FILTER ---
          ExpansionTile(
            title: const Text("Filter Pencarian",
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.filter_list),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              TextField(
                controller: prov.namaController,
                decoration: const InputDecoration(
                  labelText: "Nama Siswa",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: prov.kelasController,
                decoration: const InputDecoration(
                  labelText: "Kelas (Misal: X AK 1)",
                  prefixIcon: Icon(Icons.class_),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(prov.tanggalAwal == null
                          ? "Pilih Tanggal"
                          : "${prov.tanggalAwal.toString().split(' ')[0]} s/d ${prov.tanggalAkhir.toString().split(' ')[0]}"),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: prov.tanggalAwal != null && prov.tanggalAkhir != null
                              ? DateTimeRange(start: prov.tanggalAwal!, end: prov.tanggalAkhir!)
                              : null,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          prov.setTanggalRange(picked.start, picked.end);
                        }
                      },
                    ),
                  ),
                  if (prov.tanggalAwal != null)
                    IconButton(
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.clear, size: 20, color: Colors.black54),
                      tooltip: "Hapus Filter Tanggal",
                      onPressed: () => prov.clearTanggalRange(),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    tooltip: "Reset Filter",
                    onPressed: () {
                      prov.resetFilter();
                      _ambilData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white),
                  onPressed: _ambilData,
                  child: const Text("Terapkan Filter"),
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // --- BAGIAN LIST DATA ---
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prov.dataPelanggaran.isEmpty
                    ? const Center(child: Text("Tidak ada data ditemukan."))
                    : ListView.builder(
                        itemCount: prov.dataPelanggaran.length,
                        itemBuilder: (context, index) {
                          final data = prov.dataPelanggaran[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            elevation: 2,
                            child: ListTile(
                              onTap: () {
                                // Cari id siswa dari beberapa kemungkinan field
                                dynamic siswaIdRaw = data['siswa_id'] ?? data['siswa_kelas_id'] ?? data['id'] ?? data['siswa'] ?? data['nis'];
                                if (siswaIdRaw == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('ID siswa tidak tersedia — perbarui API untuk menyertakan siswa_id'),
                                  ));
                                  return;
                                }

                                int? siswaId;
                                try {
                                  siswaId = int.tryParse(siswaIdRaw.toString());
                                } catch (_) {
                                  siswaId = null;
                                }

                                if (siswaId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('ID siswa invalid'),
                                  ));
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HalamanDetailPelanggaran(siswaId: siswaId ?? 0, namaSiswa: data['nama_siswa']),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                radius: 25,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${data['total_poin']}",
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const Text("Poin",
                                        style: TextStyle(
                                            fontSize: 8, color: Colors.red)),
                                  ],
                                ),
                              ),
                              title: Text(
                                data['nama_siswa'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(data['kelas'],
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total Pelanggaran: ${data['jumlah_pelanggaran']} kali",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

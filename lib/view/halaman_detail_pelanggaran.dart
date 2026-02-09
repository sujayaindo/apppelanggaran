import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/detail_pelanggaran_provider.dart';
import '../provider/auth_provider.dart';
import '../layanan/api_konfig.dart';

class HalamanDetailPelanggaran extends StatefulWidget {
  final int siswaId;
  final String? namaSiswa;

  const HalamanDetailPelanggaran({super.key, required this.siswaId, this.namaSiswa});

  @override
  State<HalamanDetailPelanggaran> createState() => _HalamanDetailPelanggaranState();
}

class _HalamanDetailPelanggaranState extends State<HalamanDetailPelanggaran> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token ?? "";
      context.read<DetailPelanggaranProvider>().ambilDetailPelanggaran(token, widget.siswaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DetailPelanggaranProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggaran', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? Center(child: Text(prov.error == 'logout' ? 'Sesi tidak valid' : prov.error!))
              : prov.detail.isEmpty
                  ? const Center(child: Text('Belum ada pelanggaran untuk siswa ini.'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        final token = context.read<AuthProvider>().user?.token ?? "";
                        await context.read<DetailPelanggaranProvider>().ambilDetailPelanggaran(token, widget.siswaId);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: prov.detail.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Header card with name + class
                            final nama = widget.namaSiswa ?? (prov.detail.isNotEmpty ? prov.detail.first['nama_siswa'] ?? '-' : '-');
                            final kelas = prov.detail.isNotEmpty ? (prov.detail.first['nama_kelas'] ?? '') : '';
                            String initials(String s) {
                              final parts = s.split(' ').where((p) => p.isNotEmpty).toList();
                              if (parts.isEmpty) return '';
                              if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
                              return (parts[0][0] + parts[1][0]).toUpperCase();
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade700]),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.white24,
                                      child: Text(initials(nama), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(nama, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                          if (kelas.isNotEmpty) const SizedBox(height: 6),
                                          if (kelas.isNotEmpty) Text(kelas, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final item = prov.detail[index - 1];
                          final fotoId = item['url_bukti_foto'] ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['nama_pelanggaran'] ?? '-',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Text('${item['poin'] ?? 0} Poin', style: const TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item['kategori'] ?? '-', style: TextStyle(color: Colors.grey.shade700)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text('Dicatat oleh: ${item['nama_pencatat'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.black54))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(item['tanggal'] ?? '-', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                    ],
                                  ),
                                  if ((item['keterangan'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(item['keterangan'] ?? '-', style: const TextStyle(fontSize: 13)),
                                  ],
                                  if (fotoId != null && fotoId.toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _lihatFoto(context, fotoId.toString()),
                                        icon: const Icon(Icons.photo, size: 18),
                                        label: const Text('Lihat Bukti Foto'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _lihatFoto(BuildContext context, String rawFoto) {
    final webStrategy = kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Foto'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
            ),
            Image.network(
              _resolveFotoUrl(rawFoto),
              loadingBuilder: (ctx, child, prog) =>
                  prog == null ? child : const Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()),
              webHtmlElementStrategy: webStrategy,
              errorBuilder: (ctx, err, stack) {
                final fallback = _resolveFotoUrl(rawFoto, driveDownload: true);
                return Image.network(
                  fallback,
                  loadingBuilder: (c, child, prog) =>
                      prog == null ? child : const Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()),
                  webHtmlElementStrategy: webStrategy,
                  errorBuilder: (c, e, s) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Gagal memuat gambar'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _resolveFotoUrl(String rawFoto, {bool driveDownload = false}) {
    final trimmed = rawFoto.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      final host = uri?.host.toLowerCase();
      final isDrive = host == 'drive.google.com' || host == 'lh3.googleusercontent.com';
      if (isDrive) {
        final encoded = Uri.encodeComponent(trimmed);
        return '${ApiKonfig.proxyFoto}?src=$encoded';
      }
      return trimmed;
    }

    final normalized = trimmed.replaceAll('\\', '/');

    if (normalized.startsWith('/')) {
      return '${ApiKonfig.baseUrl}$normalized';
    }

    if (normalized.contains('/')) {
      return '${ApiKonfig.baseUrl}/$normalized';
    }

    final hasImageExt = RegExp(r'\.(png|jpe?g|gif|webp)$', caseSensitive: false)
        .hasMatch(normalized);
    if (hasImageExt) {
      return '${ApiKonfig.baseUrl}/$normalized';
    }

    final encoded = Uri.encodeComponent(normalized);
    return '${ApiKonfig.proxyFoto}?src=$encoded';
  }
}

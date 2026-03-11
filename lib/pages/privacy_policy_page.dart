import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy & Term of Service',
              style: TextStyle(
                fontSize: 22,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Last updated: March 2026',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            _buildSection(
              '1. Pengumpulan Informasi (Data Collection)',
              'Aplikasi Network Tool memerlukan akses baca kepada alamat IP (Internet Protocol), status koneksi WiFi Anda (SSID dan Subnet), data traffik jaringan (/proc/net/dev), dan lokasi presisi (hanya jika diperlukan oleh sistem OS) agar dapat menampilkan data jaringan secara akurat. Data tersebut diproses 100% lokal di HP Anda dan tidak diunggah ke cloud.',
            ),
            _buildSection(
              '2. Keamanan Login Router',
              'Seluruh data otentikasi (alamat IP router, port API, username, password) disimpan sangat rahasia di dalam database SQLite bawaan perangkat (HP) yang aman. Pengembang TIDAK MEMILIKI AKSES DAN TIDAK AKAN MENGUMPULKAN data pribadi router Anda. Semua instruksi antara aplikasi dan MikroTik berjalan secara point-to-point tanpa middleware.',
            ),
            _buildSection(
              '3. Fitur Pihak Ketiga (Third-Party Services)',
              'Kami menggunakan API gratis publik (yaitu ipify.org dan ipinfo.io) khusus untuk satu tujuan: mengecek IP Publik (Public IP Address) dari koneksi internet Anda beserta nama perusahaannya. IP Publik Anda dibaca oleh penyedia tersebut mengikuti kebijakan privasi mereka sendiri.',
            ),
            _buildSection(
              '4. Keamanan dan Jaminan',
              'Kami berusaha menggunakan prosedur keamanan yang wajar untuk melindungi informasi Anda. Namun, tidak ada metode transmisi internet atau penyimpanan elektronik yang 100% sempurna. Anda menggunakan aplikasi ini atas kebijakan dan risiko Anda sendiri. Kerusakan perangkat jaringan di luar batas tanggung jawab kami.',
            ),
            _buildSection(
              '5. Perubahan Kebijakan Privasi',
              'Dari waktu ke waktu dan setiap ada rilis terbaru, kami mungkin memperbarui kebijakan privasi ini untuk mencerminkan perubahan cara kerja aplikasi. Kebijakan ini selalu mutlak berlaku.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.privacy_tip, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 26.0),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}

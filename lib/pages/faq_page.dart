import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> faqs = [
      {
        'question': 'Apa itu aplikasi Network Tool?',
        'answer':
            'Network Tool adalah aplikasi utilitas yang membantu Anda mengelola router MikroTik, memonitor jaringan lokal, melakukan scan perangkat, dan memberikan informasi statistik internet secara real-time.',
      },
      {
        'question': 'Bagaimana cara menambahkan router MikroTik?',
        'answer':
            'Buka menu \'MikroTik Manager\', tekan tombol tambah (+), lalu masukkan alamat IP router, username, password, dan port API (default: 8728). Pastikan HP Anda terhubung satu jaringan dengan router tersebut.',
      },
      {
        'question': 'Kenapa fitur scan jaringan gagal (error)?',
        'answer':
            'Pastikan Anda sudah memberikan izin lokasi dan jaringan lokal kepada aplikasi ini. Selain itu, pastikan perangkat Anda sedang terkoneksi ke jaringan WiFi.',
      },
      {
        'question': 'Apakah grafik trafik memakan banyak baterai?',
        'answer':
            'Tidak. Aplikasi hanya membaca sistem kecepatan WiFi secara ringan tanpa membebani prosesor (CPU). Grafik akan berhenti bekerja secara otomatis saat aplikasi diminimize (berjalan di background) untuk menghemat baterai Anda.',
      },
      {
        'question': 'Apakah data router MikroTik saya aman?',
        'answer':
            'Sangat aman. Semua data seperti IP, username, dan password router disimpan secara lokal di dalam database (SQLite) perangkat Anda sendiri. Kami tidak pernah mengirim data login Anda ke server internet manapun.',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings & FAQ'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildSectionHeader('COMMON QUESTIONS'),
          const SizedBox(height: 10),
          ...faqs.map((faq) => _buildFaqCard(context, faq, isDark)),
          const SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFaqCard(
    BuildContext context,
    Map<String, String> faq,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        title: Text(
          faq['question']!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconColor: AppConstants.primaryColor,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq['answer']!,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                height: 1.5,
                fontSize: 13,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            const Icon(Icons.hub, size: 40),
            const SizedBox(height: 8),
            const Text('Network Tool v1.0.0', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            const Text(
              'Made with ❤️ for Bos Networkers',
              style: TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

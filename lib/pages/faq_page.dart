import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: faqs.length,
        separatorBuilder: (context, index) => const Divider(height: 30),
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(
              faqs[index]['question']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: Text(
                  faqs[index]['answer']!,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

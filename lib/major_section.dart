import 'package:flutter/material.dart';

// Model untuk Jurusan
class Major {
  final String name;
  final String description;
  final String imageUrl;
  final String detailUrl;

  Major({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.detailUrl,
  });
}

// Widget untuk Menampilkan Jurusan
class MajorSection extends StatelessWidget {
  final List<Major> majors;

  const MajorSection({super.key, required this.majors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jurusan Kami',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008DDA),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Ubah menjadi 1 untuk tampilan vertikal
              childAspectRatio: 1.5, // Rasio aspek untuk setiap item
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: majors.length,
            itemBuilder: (context, index) {
              final major = majors[index];
              return Card(
                elevation: 4,
                child: Column(
                  children: [
                    Image.network(
                      major.imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        major.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        major.description,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigasi ke halaman detail jurusan
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MajorDetailScreen(major: major)),
                        );
                      },
                      child: const Text('Lihat Detail'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Contoh halaman detail jurusan (Anda perlu membuatnya)
class MajorDetailScreen extends StatelessWidget {
  final Major major;

  const MajorDetailScreen({super.key, required this.major});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(major.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(major.imageUrl),
            const SizedBox(height: 16),
            Text(
              major.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              major.description,
              style: const TextStyle(fontSize: 16),
            ),
            // Tambahkan informasi detail lainnya sesuai kebutuhan
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'galery_show.dart';

class GaleryScreen extends StatefulWidget {
  const GaleryScreen({super.key});

  @override
  _GaleryScreenState createState() => _GaleryScreenState();
}

class _GaleryScreenState extends State<GaleryScreen> {
  List<dynamic> galleryItems = [];
  Map<int, String> firstPhotos = {};
  bool isLoading = true;

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/aplikasisekolah/backend_galerisekolah/public';
    } else {
      return 'http://10.0.2.2/aplikasisekolah/backend_galerisekolah/public';
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      fetchGalleryItems();
    });
  }

  Future<String?> fetchFirstPhoto(int galeryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/photos?galery_id=$galeryId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> photos = json.decode(response.body);
        if (photos.isNotEmpty && photos[0]['image'] != null) {
          return photos[0]['image'];
        }
      }
    } catch (e) {
      print('Error fetching first photo: $e');
    }
    return null;
  }

  Future<void> fetchGalleryItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/galery'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null && responseData['data'] is List) {
          setState(() {
            galleryItems = List<dynamic>.from(responseData['data']);
          });

          for (var gallery in galleryItems) {
            if (gallery['id'] != null) {
              String? firstPhoto = await fetchFirstPhoto(gallery['id']);
              if (firstPhoto != null) {
                setState(() {
                  firstPhotos[gallery['id']] = firstPhoto;
                });
              }
            }
          }
          
          setState(() {
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Widget _buildGalleryCard(Map<String, dynamic> item) {
    final String? firstPhotoUrl = firstPhotos[item['id']];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'gallery_${item['id']}',
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: firstPhotoUrl != null
                    ? Image.network(
                        firstPhotoUrl.startsWith('http') 
                            ? firstPhotoUrl 
                            : '$baseUrl/storage/photos/$firstPhotoUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFE0E0E0),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFE0E0E0),
                        child: Center(
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['judul']?.toString() ?? 'Tidak ada judul',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008DDA),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008DDA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['kategori']?.toString() ?? 'Umum',
                        style: const TextStyle(
                          color: Color(0xFF008DDA),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yy', 'id_ID').format(
                              DateTime.parse(item['tanggal'] ?? DateTime.now().toString())
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 24,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GaleryShowPage(galery: item),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008DDA),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',  // Ganti ke asset lokal
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.school, size: 40, color: Colors.white);
              },
            ),
            SizedBox(width: 12),
            Text(
              'Galeri Sekolah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF008DDA),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF008DDA).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : galleryItems.isEmpty
                ? const Center(child: Text('Tidak ada galeri'))
                : RefreshIndicator(
                    onRefresh: fetchGalleryItems,
                    color: const Color(0xFF008DDA),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: galleryItems.length,
                      itemBuilder: (context, index) => _buildGalleryCard(galleryItems[index]),
                    ),
                  ),
      ),
    );
  }
}

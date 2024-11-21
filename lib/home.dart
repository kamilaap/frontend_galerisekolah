import 'package:flutter/material.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'info.dart';
import 'agenda.dart';
import 'package:intl/intl.dart';
import 'galery.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'profile.dart';
import 'major_section.dart'; // Impor widget MajorSection

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> sliders = [];
  List<dynamic> informations = [];
  List<dynamic> agendas = [];
  List<dynamic> galleryItems = [];
  Map<int, String> firstPhotos = {};
  bool isLoading = true;
  bool isLoggedIn = false;
  String? userRole;

  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1/aplikasisekolah/backend_galerisekolah/public';
    } else {
      return 'http://10.0.2.2/aplikasisekolah/backend_galerisekolah/public';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSliders();
    fetchInformations();
    fetchAgendas();
    checkLoginStatus();
    fetchGalleryItems();
  }

  Future<String?> fetchFirstPhoto(int galleryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/photos?galery_id=$galleryId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> photos = json.decode(response.body);
        if (photos.isNotEmpty && photos[0]['image'] != null) {
          String imageUrl = photos[0]['image'];
          if (!kIsWeb) {
            imageUrl = imageUrl.replaceAll('localhost', '10.0.2.2');
          }
          return imageUrl;
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
        }
      }
    } catch (e) {
      print('Error fetching gallery: $e');
    }
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    setState(() {
      isLoggedIn = token != null;
      userRole = role;
    });
  }

  Future<void> logout() async {
    // Tampilkan dialog konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(
              color: Color(0xFF008DDA),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008DDA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ya, Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
    );

    // Jika user menekan tombol Ya, Logout
    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        final response = await http.post(
          Uri.parse('$baseUrl/api/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          await prefs.clear();
          setState(() {
            isLoggedIn = false;
            userRole = null;
          });

          // Tampilkan snackbar sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Berhasil logout'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Arahkan ke halaman login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gagal logout. Silakan coba lagi.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Terjadi kesalahan. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    if (imagePath.startsWith('/storage/')) {
      imagePath = imagePath.replaceFirst('/storage/', '');
    }
    
    String url = '$baseUrl/storage/$imagePath';
    
    if (!kIsWeb) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    
    return url;
  }

  Future<void> fetchSliders() async {
    try {
      print('Fetching sliders from: ${baseUrl}/api/sliders');  // Debug URL
      final response = await http.get(
        Uri.parse('${baseUrl}/api/sliders'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));  // Tambah timeout

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          setState(() {
            sliders = List<dynamic>.from(responseData['data']);
            isLoading = false;
          });
        }
      } else {
        print('Error status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
          sliders = [];
        });
      }
    } catch (e) {
      print('Error fetching sliders: $e');
      setState(() {
        isLoading = false;
        sliders = [];
      });
    }
  }

  Future<void> fetchInformations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/informasi'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          informations = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching informations: $e');
    }
  }

  Future<void> fetchAgendas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/agenda'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          agendas = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching agendas: $e');
    }
  }

  String formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
  }

  String truncateDescription(String text) {
    List<String> sentences = text.split(RegExp(r'[.!?]+\s*'));
    if (sentences.length > 3) {
      return '${sentences.take(3).join('. ')}...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: Row(
    children: [
      Image.asset(
        'assets/images/logo.png',
        height: 40,
        width: 40,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.school,
            color: Colors.white,
            size: 40,
          );
        },
      ),
      const SizedBox(width: 8),
      const Text(
        'Edu Galery',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF008DDA), Color(0xFF00BFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (!isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            )
          else if (userRole == 'user')
            PopupMenuButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context); // Close menu first
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen()),
                      );
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(context); // Close menu first
                      logout();
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchSliders();
                await fetchInformations();
                await fetchAgendas();
                await fetchGalleryItems();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Enhanced Carousel Slider
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3, // Responsif
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: sliders.isEmpty 
                          ? const Center(child: Text('Tidak ada slider tersedia'))
                          : CarouselSlider(
                              slideTransform: const CubeTransform(
                                rotationAngle: 0.1,
                                perspectiveScale: 0.002,
                              ),
                              slideIndicator: CircularWaveSlideIndicator(
                                padding: const EdgeInsets.only(bottom: 20),
                                currentIndicatorColor: const Color(0xFF008DDA),
                                indicatorBackgroundColor: Colors.white,
                                indicatorRadius: 4,
                              ),
                              unlimitedMode: true,
                              autoSliderTransitionTime: const Duration(seconds: 2),
                              enableAutoSlider: true,
                              children: sliders.map((slider) {
                                final imageUrl = getImageUrl(slider['image'] ?? '');
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: CircularProgressIndicator());
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.error, color: Colors.red[300], size: 40),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Gagal memuat gambar',
                                                      style: TextStyle(
                                                        color: Colors.red[300],
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.6),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (slider['caption'] != null)
                                          Positioned(
                                            bottom: 20,
                                            left: 16,
                                            right: 16,
                                            child: Text(
                                              slider['caption'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(1, 1),
                                                    blurRadius: 3,
                                                    color: Colors.black.withOpacity(0.5),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang di Edu Galery',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF008DDA),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Membentuk generasi unggul, berkarakter, dan siap untuk masa depan.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gallery Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Galeri Foto',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008DDA),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => GaleryScreen()),
                                  );
                                },
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(color: Color(0xFF008DDA)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: galleryItems.isEmpty
                                ? const Center(child: Text('Tidak ada galeri tersedia'))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: galleryItems.length,
                                    itemBuilder: (context, index) {
                                      final gallery = galleryItems[index];
                                      final String? firstPhotoUrl = firstPhotos[gallery['id']];
                                      
                                      return Container(
                                        width: 180,
                                        margin: const EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: firstPhotoUrl != null
                                                  ? Image.network(
                                                      firstPhotoUrl,
                                                      height: 140,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          height: 140,
                                                          color: Colors.grey[300],
                                                          child: const Icon(Icons.image_not_supported),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      height: 140,
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.image_not_supported),
                                                    ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                gallery['judul'] ?? 'No Title',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Informasi Terkini
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Informasi Terkini',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008DDA),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => InformasiScreen()),
                                  );
                                },
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(color: Color(0xFF008DDA)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: informations.length,
                              itemBuilder: (context, index) {
                                final info = informations[index];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              getImageUrl(info['image'] ?? ''),
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 180,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image_not_supported, size: 50),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  info['judul'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          info['deskripsi'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Agenda Sekolah
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Agenda Sekolah',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008DDA),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AgendaScreen()),
                                  );
                                },
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(color: Color(0xFF008DDA)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: agendas.length,
                            itemBuilder: (context, index) {
                              final agenda = agendas[index];
                              String description = truncateDescription(agenda['deskripsi'] ?? '');
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50], // Warna latar belakang yang lebih cerah
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event, color: Color(0xFF008DDA), size: 30), // Ikon agenda
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            agenda['judul'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            description,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    if (userRole == 'admin') 
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Slider'),
                              onPressed: () {
                                // Tampilkan dialog/form untuk menambah slider
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF008DDA),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Tambahkan section Contact sebelum akhir SingleChildScrollView
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kontak Kami',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF008DDA),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Nama',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF008DDA)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF008DDA)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: 'Pesan',
                                    prefixIcon: const Icon(Icons.message),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF008DDA)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Implementasi pengiriman pesan
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF008DDA),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Kirim Pesan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Informasi kontak tambahan
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF008DDA)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Jl. Raya Tajur, Kp. Buntar RT.02/RW.08, Kel. Muara Sari, Kec. Bogor Selatan, Kota Bogor',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Icon(Icons.email, color: Color(0xFF008DDA)),
                              SizedBox(width: 8),
                              Text(
                                'smkn4bogor@gmail.com',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Icon(Icons.phone, color: Color(0xFF008DDA)),
                              SizedBox(width: 8),
                              Text(
                                '(0251) 7547381',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: const Color(0xFFE3F2FD), // Warna latar belakang yang lebih cerah
    );
  }
}

class SchoolProfile extends StatelessWidget {
  const SchoolProfile({super.key});

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Sekolah',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008DDA),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Sekolah ini merupakan sekolah kejuruan berbasis Teknologi Informasi dan Komunikasi. Sekolah ini didirikan dan dirintis pada tahun 2008 kemudian dibuka pada tahun 2009 yang saat ini terakreditasi A.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class MajorSection extends StatelessWidget {
  final List<Map<String, String>> majors;

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
          ...majors.map((major) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                major['name'] ?? '',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

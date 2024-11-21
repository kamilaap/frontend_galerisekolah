import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:share_plus/share_plus.dart';

class GaleryShowPage extends StatefulWidget {
  final Map<String, dynamic> galery;

  const GaleryShowPage({Key? key, required this.galery}) : super(key: key);

  @override
  State<GaleryShowPage> createState() => _GaleryShowPageState();
}

class _GaleryShowPageState extends State<GaleryShowPage> {
  List<dynamic> photos = [];
  bool isLoading = true;
  String? userRole;
  String? token;
  final TextEditingController commentController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/aplikasisekolah/backend_galerisekolah/public';
    } else {
      return 'http://10.0.2.2/aplikasisekolah/backend_galerisekolah/public';
    }
  }

  Future<void> fetchPhotos() async {
    try {
      final galeryId = widget.galery['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/photos?galery_id=$galeryId'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          photos = data;
          isLoading = false;
        });
        print('Loaded ${photos.length} photos');
      }
    } catch (e) {
      print('Error fetching photos: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadUserData();
      fetchPhotos().then((_) {
        for (var photo in photos) {
          fetchLikes(photo['id']);
          fetchComments(photo['id']);
        }
      });
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role');
      token = prefs.getString('token');
    });
  }

  // Fungsi untuk mengambil likes
  Future<void> fetchLikes(int photoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/photos/$photoId/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            final photoIndex = photos.indexWhere((p) => p['id'] == photoId);
            if (photoIndex != -1) {
              photos[photoIndex]['likes'] = data['data'];
              photos[photoIndex]['likes_count'] = data['total_likes'];
              // Cek apakah user yang login sudah like
              photos[photoIndex]['is_liked'] = data['data']
                  .any((like) => like['user_name'] == userRole);
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching likes: $e');
    }
  }

  // Fungsi untuk toggle like
  Future<void> toggleLike(int photoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/photos/$photoId/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Refresh likes setelah toggle
        fetchLikes(photoId);
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to like photo')),
      );
    }
  }

  // Fungsi untuk mengambil comments
  Future<void> fetchComments(int photoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/photos/$photoId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            final photoIndex = photos.indexWhere((p) => p['id'] == photoId);
            if (photoIndex != -1) {
              photos[photoIndex]['comments'] = data['data'];
              photos[photoIndex]['comments_count'] = data['data'].length;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  // Fungsi untuk menambah komentar
  Future<void> addComment(int photoId) async {
    if (commentController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/photos/$photoId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'comment': commentController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Clear comment input
          commentController.clear();
          
          // Refresh comments
          fetchComments(photoId);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk mengambil likes dan comments
  Future<Map<String, dynamic>> fetchPhotoDetails(int photoId) async {
    try {
      final likesResponse = await http.get(
        Uri.parse('$baseUrl/api/photos/$photoId/likes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final commentsResponse = await http.get(
        Uri.parse('$baseUrl/api/photos/$photoId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return {
        'likes': json.decode(likesResponse.body),
        'comments': json.decode(commentsResponse.body),
      };
    } catch (e) {
      print('Error fetching photo details: $e');
      return {'likes': [], 'comments': []};
    }
  }

  Widget _buildPhotoCard(dynamic photo, BuildContext context) {
    String imageUrl = photo['image']?.toString() ?? '';
    if (!kIsWeb) {
      imageUrl = imageUrl.replaceAll('localhost', '10.0.2.2');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Image with Hero animation
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imageUrl),
            child: Hero(
              tag: 'photo_${photo['id']}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300, // Tinggi foto lebih besar
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008DDA)),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300, // Tinggi foto lebih besar
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat gambar',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Photo title and details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo['judul'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008DDA),
                  ),
                ),
                const SizedBox(height: 8),
                if (photo['deskripsi'] != null)
                  Text(
                    photo['deskripsi'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),

          // Interaction section
          if (userRole == 'user')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  // Like button
                  _buildInteractionButton(
                    icon: photo['is_liked'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: photo['is_liked'] == true ? Colors.red : Colors.grey[600],
                    count: photo['likes_count'] ?? 0,
                    onTap: () => toggleLike(photo['id']),
                  ),
                  const SizedBox(width: 24),
                  // Comment button
                  _buildInteractionButton(
                    icon: Icons.comment,
                    color: Colors.grey[600],
                    count: photo['comments_count'] ?? 0,
                    onTap: () => showCommentDialog(context, photo['id']),
                  ),
                  const Spacer(),
                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF008DDA)),
                    onPressed: () => _sharePhoto(photo),
                  ),
                ],
              ),
            ),

          // Comments section
          if (photo['comments'] != null && photo['comments'].isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF008DDA),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    photo['comments'].length > 3 
                        ? 3 
                        : photo['comments'].length,
                    (index) => _buildCommentItem(photo['comments'][index]),
                  ),
                  if (photo['comments'].length > 3)
                    TextButton(
                      onPressed: () => _showAllComments(photo['comments']),
                      child: const Text(
                        'Lihat semua komentar',
                        style: TextStyle(color: Color(0xFF008DDA)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color? color,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    String formattedDate;
    try {
      final DateTime dateTime = DateTime.parse(comment['created_at']);
      formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      formattedDate = 'Tanggal tidak valid';
      print('Error parsing date: $e');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF008DDA),
            child: Text(
              comment['user_name']?[0]?.toUpperCase() ?? '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['user_name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['comment'] ?? '',
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand, // Memastikan stack mengisi seluruh layar
              children: [
                // Gesture detector untuk zoom dan pan
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Hero(
                        tag: imageUrl,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.white, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllComments(List<dynamic> comments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Semua Komentar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF008DDA),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: comments.length,
                  padding: const EdgeInsets.only(top: 16),
                  itemBuilder: (context, index) => _buildCommentItem(comments[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              'https://smkn4bogor.sch.id/assets/images/logo/logoSMKN4.svg',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            Text(
              widget.galery['judul'] ?? 'Gallery',
              style: const TextStyle(
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008DDA)),
              ),
            )
          : photos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada foto dalam galeri ini',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPhotos,
                  color: const Color(0xFF008DDA),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: photos.length,
                    itemBuilder: (context, index) => _buildPhotoCard(photos[index], context),
                  ),
                ),
      ),
    );
  }

  void showCommentDialog(BuildContext context, int photoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              addComment(photoId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008DDA),
            ),
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan likes
  Widget buildLikes(List<dynamic> likes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.red, size: 20),
          const SizedBox(width: 4),
          Text(
            '${likes.length} likes',
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          if (likes.isNotEmpty)
            TextButton(
              onPressed: () {
                showLikesDialog(likes);
              },
              child: const Text('View all'),
            ),
        ],
      ),
    );
  }

  // Dialog untuk menampilkan daftar likes
  void showLikesDialog(List<dynamic> likes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Likes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final like = likes[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(like['user_name'][0].toUpperCase()),
                ),
                title: Text(like['user_name']),
                subtitle: Text(like['created_at']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan comments
  Widget buildComments(List<dynamic> comments, int photoId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header with add comment button
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments (${comments.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (userRole == 'user') // Only show for users
                TextButton.icon(
                  onPressed: () => showCommentDialog(context, photoId),
                  icon: const Icon(Icons.add_comment),
                  label: const Text('Add Comment'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF008DDA),
                  ),
                ),
            ],
          ),
        ),
        
        // Comments list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF008DDA),
                          foregroundColor: Colors.white,
                          child: Text(comment['user_name'][0].toUpperCase()),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['user_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              comment['created_at'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment['comment'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _sharePhoto(Map<String, dynamic> photo) async {
    final String shareText = '''
${photo['judul'] ?? 'Photo'}

${photo['deskripsi'] ?? ''}

Lihat lebih banyak foto di aplikasi Galeri Sekolah
''';

    try {
      await Share.share(
        shareText,
        subject: photo['judul'] ?? 'Photo from Galeri Sekolah',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membagikan foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
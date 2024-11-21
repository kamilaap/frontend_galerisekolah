import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  _AdminGalleryScreenState createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  List<dynamic> galleryList = [];
  bool isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchGallery();
  }

  Future<void> fetchGallery() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          'http://localhost/aplikasisekolah/backend_galerisekolah/public/api/galery'));
      if (response.statusCode == 200) {
        setState(() {
          galleryList = json.decode(response.body)['data'];
        });
      } else {
        showError('Gagal memuat galeri, status code: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      showError('Gagal memilih gambar: $e');
    }
  }

  Future<void> createGallery() async {
    if (_imageFile == null) {
      showError('Pilih gambar terlebih dahulu');
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://localhost/aplikasisekolah/backend_galerisekolah/public/api/galery'),
      );

      request.fields['judul'] = _judulController.text;
      request.fields['deskripsi'] = _deskripsiController.text;

      request.files.add(await http.MultipartFile.fromPath(
        'gambar',
        _imageFile!.path,
      ));

      var response = await request.send();
      if (response.statusCode == 201) {
        clearForm();
        fetchGallery();
        showMessage('Galeri berhasil ditambahkan');
      } else {
        showError('Gagal menambahkan galeri, status code: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  Future<void> updateGallery(int id) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse(
            'http://localhost/aplikasisekolah/backend_galerisekolah/public/api/galery/$id'),
      );

      request.fields['judul'] = _judulController.text;
      request.fields['deskripsi'] = _deskripsiController.text;
      request.fields['_method'] = 'PUT'; 

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'gambar',
          _imageFile!.path,
        ));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        clearForm();
        fetchGallery();
        showMessage('Galeri berhasil diupdate');
      } else {
        showError('Gagal memperbarui galeri, status code: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  Future<void> deleteGallery(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'http://localhost/aplikasisekolah/backend_galerisekolah/public/api/galery/$id'),
      );
      if (response.statusCode == 200) {
        fetchGallery();
        showMessage('Galeri berhasil dihapus');
      } else {
        showError('Gagal menghapus galeri, status code: ${response.statusCode}');
      }
    } catch (e) {
      showError('Error: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void clearForm() {
    _judulController.clear();
    _deskripsiController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : galleryList.isEmpty
              ? const Center(child: Text('Tidak ada data galeri'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: galleryList.length,
                  itemBuilder: (context, index) {
                    final gallery = galleryList[index];
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Image.network(
                              'http://localhost/aplikasisekolah/backend_galerisekolah/public/storage/${gallery['gambar']}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gallery['judul'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  gallery['deskripsi'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          OverflowBar(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _judulController.text = gallery['judul'];
                                  _deskripsiController.text = gallery['deskripsi'];
                                  _showFormDialog(context, isEdit: true, id: gallery['id']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteDialog(context, gallery['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFormDialog(BuildContext context, {bool isEdit = false, int? id}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Galeri' : 'Tambah Galeri'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _judulController,
                  decoration: const InputDecoration(labelText: 'Judul'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Judul tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Deskripsi tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pilih Gambar'),
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 8),
                  Image.file(
                    _imageFile!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearForm();
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (isEdit) {
                  updateGallery(id!);
                } else {
                  createGallery();
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Galeri'),
        content: const Text('Apakah Anda yakin ingin menghapus galeri ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              deleteGallery(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

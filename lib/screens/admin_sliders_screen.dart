import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminSlidersScreen extends StatefulWidget {
  const AdminSlidersScreen({super.key});

  @override
  _AdminSlidersScreenState createState() => _AdminSlidersScreenState();
}

class _AdminSlidersScreenState extends State<AdminSlidersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _linkController = TextEditingController();
  List<dynamic> slidersList = [];
  bool isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchSliders();
  }

  Future<void> fetchSliders() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          'http://localhost/aplikasisekolah/backend_galerisekolah/public/api/sliders'));
      if (response.statusCode == 200) {
        setState(() {
          slidersList = json.decode(response.body)['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> createSlider() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar terlebih dahulu')),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost/aplikasisekolah/backend_galerisekolah/public/api/sliders'),
      );

      request.fields['judul'] = _judulController.text;
      request.fields['link'] = _linkController.text;
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _imageFile!.path,
      ));

      var response = await request.send();
      if (response.statusCode == 201) {
        clearForm();
        fetchSliders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slider berhasil ditambahkan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateSlider(int id) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost/aplikasisekolah/backend_galerisekolah/public/api/sliders/$id'),
      );

      request.fields['judul'] = _judulController.text;
      request.fields['link'] = _linkController.text;
      request.fields['_method'] = 'PUT';

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
        ));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        clearForm();
        fetchSliders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slider berhasil diupdate')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> deleteSlider(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost/aplikasisekolah/backend_galerisekolah/public/api/sliders/$id'),
      );
      if (response.statusCode == 200) {
        fetchSliders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slider berhasil dihapus')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void clearForm() {
    _judulController.clear();
    _linkController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: slidersList.length,
              itemBuilder: (context, index) {
                final slider = slidersList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        'http://localhost/aplikasisekolah/backend_galerisekolah/public/storage/${slider['image']}',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slider['judul'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Link: ${slider['link']}'),
                            OverflowBar(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  onPressed: () {
                                    _judulController.text = slider['judul'];
                                    _linkController.text = slider['link'];
                                    _showFormDialog(context, isEdit: true, id: slider['id']);
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Hapus'),
                                  onPressed: () => _showDeleteDialog(context, slider['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
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
        title: Text(isEdit ? 'Edit Slider' : 'Tambah Slider'),
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
                  controller: _linkController,
                  decoration: const InputDecoration(labelText: 'Link'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Link tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Gambar'),
                  onPressed: _pickImage,
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
                  updateSlider(id!);
                } else {
                  createSlider();
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEdit ? 'Update' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus slider ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              deleteSlider(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _linkController.dispose();
    super.dispose();
  }
} 
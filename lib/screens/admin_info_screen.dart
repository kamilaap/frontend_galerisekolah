import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AdminInformasiScreen extends StatefulWidget {
  const AdminInformasiScreen({super.key});

  @override
  _AdminInformasiScreenState createState() => _AdminInformasiScreenState();
}

class _AdminInformasiScreenState extends State<AdminInformasiScreen> {
  List<dynamic> informasiList = [];
  bool isLoading = true;
  File? selectedImage;

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInformasi();
  }

  Future<void> fetchInformasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/informasi'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          informasiList = responseData['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> showFormDialog({Map<String, dynamic>? info}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: info?['judul']);
    final descController = TextEditingController(text: info?['deskripsi']);
    DateTime? selectedDate = info != null ? DateTime.parse(info['tanggal']) : null;
    File? imageFile;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info == null ? 'Tambah Informasi' : 'Edit Informasi'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Tanggal: ${selectedDate != null 
                        ? DateFormat('dd MMM yyyy').format(selectedDate!)
                        : 'Pilih Tanggal'}'
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Gambar'),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null) {
                      imageFile = File(result.files.single.path!);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008DDA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedDate != null) {
                if (info == null) {
                  // Create
                  await createInformasi(
                    titleController.text,
                    descController.text,
                    selectedDate!,
                    imageFile,
                  );
                } else {
                  // Update
                  await updateInformasi(
                    info['id'],
                    titleController.text,
                    descController.text,
                    selectedDate!,
                    imageFile,
                  );
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008DDA),
            ),
            child: Text(info == null ? 'Simpan' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> createInformasi(String title, String description, DateTime date, File? image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/informasi'));
      
      request.fields.addAll({
        'judul': title,
        'deskripsi': description,
        'tanggal': date.toIso8601String(),
        'kategori_id': '1',
        'status': 'active',
      });

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      final response = await request.send();
      
      if (response.statusCode == 201) {
        showSuccessMessage('Berhasil menambah informasi');
        fetchInformasi();
      } else {
        showErrorMessage('Gagal menambah informasi');
      }
    } catch (e) {
      showErrorMessage('Error: $e');
    }
  }

  Future<void> updateInformasi(int id, String title, String description, DateTime date, File? image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/informasi/$id'));
      
      request.fields.addAll({
        '_method': 'PUT',
        'judul': title,
        'deskripsi': description,
        'tanggal': date.toIso8601String(),
        'kategori_id': '1',
        'status': 'active',
      });

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      final response = await request.send();
      
      if (response.statusCode == 200) {
        showSuccessMessage('Berhasil mengupdate informasi');
        fetchInformasi();
      } else {
        showErrorMessage('Gagal mengupdate informasi');
      }
    } catch (e) {
      showErrorMessage('Error: $e');
    }
  }

  Future<void> deleteInformasi(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus informasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/informasi/$id'),
          headers: {'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          showSuccessMessage('Berhasil menghapus informasi');
          fetchInformasi();
        } else {
          showErrorMessage('Gagal menghapus informasi');
        }
      } catch (e) {
        showErrorMessage('Error: $e');
      }
    }
  }

  void showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Informasi'),
        backgroundColor: const Color(0xFF008DDA),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: informasiList.length,
              itemBuilder: (context, index) {
                final info = informasiList[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info['image'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            '$baseUrl/storage/${info['image']}',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info['judul'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              info['deskripsi'] ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF008DDA)),
                                  onPressed: () => showFormDialog(info: info),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteInformasi(info['id']),
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
        onPressed: () => showFormDialog(),
        backgroundColor: const Color(0xFF008DDA),
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAgendaScreen extends StatefulWidget {
  const AdminAgendaScreen({super.key});

  @override
  _AdminAgendaScreenState createState() => _AdminAgendaScreenState();
}

class _AdminAgendaScreenState extends State<AdminAgendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalController = TextEditingController();
  List<dynamic> agendaList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAgenda();
  }

  Future<void> fetchAgenda() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          'http://localhost/aplikasisekolah/backend_galerisekolah/public/api/agenda'));
      if (response.statusCode == 200) {
        setState(() {
          agendaList = json.decode(response.body)['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> createAgenda() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/aplikasisekolah/backend_galerisekolah/public/api/agenda'),
        body: {
          'judul': _judulController.text,
          'deskripsi': _deskripsiController.text,
          'tanggal': _tanggalController.text,
        },
      );
      if (response.statusCode == 201) {
        clearForm();
        fetchAgenda();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda berhasil ditambahkan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateAgenda(int id) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost/aplikasisekolah/backend_galerisekolah/public/api/agenda/$id'),
        body: {
          'judul': _judulController.text,
          'deskripsi': _deskripsiController.text,
          'tanggal': _tanggalController.text,
        },
      );
      if (response.statusCode == 200) {
        clearForm();
        fetchAgenda();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda berhasil diupdate')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> deleteAgenda(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost/aplikasisekolah/backend_galerisekolah/public/api/agenda/$id'),
      );
      if (response.statusCode == 200) {
        fetchAgenda();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda berhasil dihapus')),
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
    _deskripsiController.clear();
    _tanggalController.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: agendaList.length,
              itemBuilder: (context, index) {
                final agenda = agendaList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(agenda['judul']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agenda['deskripsi']),
                        Text('Tanggal: ${agenda['tanggal']}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _judulController.text = agenda['judul'];
                            _deskripsiController.text = agenda['deskripsi'];
                            _tanggalController.text = agenda['tanggal'];
                            _showFormDialog(context, isEdit: true, id: agenda['id']);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteDialog(context, agenda['id']),
                        ),
                      ],
                    ),
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
        title: Text(isEdit ? 'Edit Agenda' : 'Tambah Agenda'),
        content: Form(
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
              TextFormField(
                controller: _tanggalController,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Tanggal tidak boleh kosong' : null,
              ),
            ],
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
                  updateAgenda(id!);
                } else {
                  createAgenda();
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
        content: const Text('Yakin ingin menghapus agenda ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              deleteAgenda(id);
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
    _deskripsiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }
} 
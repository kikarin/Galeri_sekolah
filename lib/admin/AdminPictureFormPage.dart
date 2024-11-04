import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AdminPictureFormPage extends StatefulWidget {
  final Map<String, dynamic>? picture;
  final int albumId;

  AdminPictureFormPage({this.picture, required this.albumId});

  @override
  _AdminPictureFormPageState createState() => _AdminPictureFormPageState();
}

class _AdminPictureFormPageState extends State<AdminPictureFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imageUrlController = TextEditingController();
  File? _selectedImage;
  bool isLoading = false;
  bool isEditMode = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.picture != null) {
      isEditMode = true;
      _imageUrlController.text = widget.picture!['image_url'] ?? '';
    }
  }

  /// Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrlController.clear(); // Kosongkan URL jika gambar dipilih
      });
    }
  }

  /// Fungsi untuk menyimpan gambar baru atau mengupdate gambar yang ada
  Future<void> savePicture() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Tentukan URL untuk add dan edit
      final url = isEditMode
          ? 'http://192.168.137.19:8000/api/pictures/${widget.picture!['id']}?_method=PUT'
          : 'http://192.168.137.19:8000/api/albums/${widget.albumId}/pictures';

      // Gunakan POST untuk multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Tambahkan field gambar atau URL
      request.fields['album_id'] = widget.albumId.toString();
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // Field name di Laravel
            _selectedImage!.path,
          ),
        );
      } else if (_imageUrlController.text.isNotEmpty) {
        request.fields['image_url'] = _imageUrlController.text;
      } else {
        throw Exception('Please provide an image or image URL.');
      }

      // Kirim request dan cek respons
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // Berhasil, kembali ke halaman sebelumnya
      } else {
        throw Exception('Failed to save picture: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Fungsi untuk menampilkan pesan kesalahan
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Picture' : 'Add Picture'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (!isEditMode) // Tombol pilih gambar saat tambah baru
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Pick Image from Gallery'),
                      ),
                    const SizedBox(height: 10),
                    if (_selectedImage != null) // Tampilkan gambar yang dipilih
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                      validator: (value) {
                        if (_selectedImage == null &&
                            (value == null || value.isEmpty)) {
                          return 'Please provide an image or image URL.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : savePicture,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

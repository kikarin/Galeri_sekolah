import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AdminPictureFormPage extends StatefulWidget {
  final int albumId;

  AdminPictureFormPage({required this.albumId});

  @override
  _AdminPictureFormPageState createState() => _AdminPictureFormPageState();
}

class _AdminPictureFormPageState extends State<AdminPictureFormPage> {
  final _formKey = GlobalKey<FormState>();
  List<File> _selectedImages = [];
  bool isLoading = false;

  final picker = ImagePicker();

  /// Fungsi untuk memilih beberapa gambar dari galeri
  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  /// Fungsi untuk menyimpan gambar baru
  Future<void> savePictures() async {
    if (_selectedImages.isEmpty) {
      _showErrorDialog('Please select at least one image.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url =
          'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums/${widget.albumId}/pictures';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['album_id'] = widget.albumId.toString();

      // Tambahkan gambar baru
      for (var imageFile in _selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]', // Pastikan sesuai dengan API
            imageFile.path,
          ),
        );
      }

      // Kirim request dan cek respons
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // Berhasil, kembali ke halaman sebelumnya
      } else {
        throw Exception('Failed to save pictures: ${response.body}');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pictures'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    ElevatedButton(
                      onPressed: _pickImages,
                      child: const Text('Pick Images from Gallery'),
                    ),
                    const SizedBox(height: 10),
                    // Tampilkan gambar yang dipilih
                    if (_selectedImages.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _selectedImages
                            .map((image) => Image.file(
                                  image,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : savePictures,
                      child: const Text('Save All'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

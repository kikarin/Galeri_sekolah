import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  double uploadProgress = 0.0;

  final picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles != null) {
        for (var pickedFile in pickedFiles) {
          File file = File(pickedFile.path);
          
          // Hitung ukuran file dalam MB
          double fileSize = file.lengthSync() / (1024 * 1024);
          
          // Validasi ukuran file (maksimal 50 MB)
          if (fileSize > 50) {
            _showErrorDialog(
              'File ${p.basename(file.path)} terlalu besar (${fileSize.toStringAsFixed(2)} MB).\n'
              'Maksimal ukuran file adalah 50 MB.'
            );
            continue; // Lewati file yang terlalu besar
          }

          setState(() {
            _selectedImages.add(file);
          });
        }

        if (_selectedImages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_selectedImages.length} gambar dipilih\n'
                'Gambar akan dikompresi menjadi 90% dari kualitas asli'
              ),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}');
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 90,
        rotate: 0,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error during compression: $e');
      return null;
    }
  }

  Future<void> savePictures() async {
    if (_selectedImages.isEmpty) {
      _showErrorDialog('Pilih minimal satu gambar.');
      return;
    }

    setState(() {
      isLoading = true;
      uploadProgress = 0.0;
    });

    try {
      final url = 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums/${widget.albumId}/pictures';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['album_id'] = widget.albumId.toString();

      // Kompresi dan tambahkan semua gambar
      for (var imageFile in _selectedImages) {
        File? compressedImage = await compressImage(imageFile);
        if (compressedImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              compressedImage.path,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[]',
              imageFile.path,
            ),
          );
        }
      }

      // Kirim request tanpa monitoring progress yang berlebihan
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (responseData.statusCode == 200 || responseData.statusCode == 201) {
        // Langsung kembali ke halaman sebelumnya tanpa peringatan
        Navigator.pop(context, true);
      } else {
        // Hanya tampilkan error jika benar-benar gagal
        throw Exception('Gagal mengunggah gambar');
      }
    } catch (e) {
      // Tampilkan dialog error hanya jika benar-benar gagal
      if (mounted) {
        _showErrorDialog('Gagal mengunggah gambar: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Peringatan'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Tutup'),
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
        title: Text('Tambah Gambar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: uploadProgress),
                  SizedBox(height: 20),
                  Text(
                    'Uploading: ${(uploadProgress * 100).toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: Icon(Icons.photo_library),
                      label: Text('Pilih Gambar dari Galeri'),
                    ),
                    SizedBox(height: 10),
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                children: [
                                  Image.file(
                                    _selectedImages[index],
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : savePictures,
                      child: Text('Simpan Semua'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

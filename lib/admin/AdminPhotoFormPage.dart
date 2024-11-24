import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AdminPhotoFormPage extends StatefulWidget {
  final int galleryId;
  final Map<String, dynamic>? photo;

  AdminPhotoFormPage({required this.galleryId, this.photo});

  @override
  _AdminPhotoFormPageState createState() => _AdminPhotoFormPageState();
}

class _AdminPhotoFormPageState extends State<AdminPhotoFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _imageUrlController = TextEditingController();
  File? _pickedImage;
  bool isLoading = false;
  bool isEditMode = false;
  double uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.photo != null) {
      isEditMode = true;
      _titleController.text = widget.photo!['title'];
      _descriptionController.text = widget.photo!['description'] ?? '';
      _imageUrlController.text = widget.photo!['image_url'];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        File file = File(pickedFile.path);
        
        // Hitung ukuran file dalam MB
        double fileSize = file.lengthSync() / (1024 * 1024);
        
        // Validasi ukuran file (maksimal 50 MB)
        if (fileSize > 50) {
          _showErrorDialog(
            'File terlalu besar (${fileSize.toStringAsFixed(2)} MB).\n'
            'Maksimal ukuran file adalah 50 MB.\n'
            'Silakan pilih file yang lebih kecil atau kompres terlebih dahulu.'
          );
          return;
        }

        setState(() {
          _pickedImage = file;
        });

        // Tampilkan informasi ukuran file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ukuran file: ${fileSize.toStringAsFixed(2)} MB\n'
              'File akan dikompresi menjadi 90% dari kualitas asli'
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 90, // Ubah kompresi menjadi 90%
        rotate: 0,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error during compression: $e');
      return null;
    }
  }

  Future<void> savePhoto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      uploadProgress = 0.0;
    });

    try {
      final url = isEditMode
          ? 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/${widget.photo!['id']}/update'
          : 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos';

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['gallery_id'] = widget.galleryId.toString();

      if (_pickedImage != null) {
        File? compressedImage = await compressImage(_pickedImage!);
        if (compressedImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', compressedImage.path),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath('image', _pickedImage!.path),
          );
        }
      } else if (_imageUrlController.text.isNotEmpty) {
        request.fields['image_url'] = _imageUrlController.text;
      } else if (isEditMode) {
        request.fields['image_url'] = widget.photo!['image_url'];
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (responseData.statusCode == 200 || responseData.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal menyimpan foto');
      }
    } catch (e) {
      _showErrorDialog('Gagal menyimpan foto: ${e.toString()}');
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
        actions: [
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Photo' : 'Add Photo'),
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
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value!.isEmpty ? 'Title is required' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    _pickedImage == null
                        ? Column(
                            children: [
                              TextFormField(
                                controller: _imageUrlController,
                                decoration:
                                    InputDecoration(labelText: 'Image URL'),
                                validator: (value) {
                                  if (value!.isEmpty && _pickedImage == null) {
                                    return 'Image URL or picked image is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 10),
                              Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Text(
                                    'No Image Selected',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Image.file(
                            _pickedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icon(Icons.photo_library),
                          label: Text('Gallery'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icon(Icons.camera_alt),
                          label: Text('Camera'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: savePhoto,
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

Future<void> savePhoto() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isLoading = true;
  });

  try {
    final url = isEditMode
        ? 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/${widget.photo!['id']}/update'
        : 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos';

    // Gunakan POST untuk update dan add
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Tambahkan field data
    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;
    request.fields['gallery_id'] = widget.galleryId.toString();

    // Tambahkan file gambar jika ada
    if (_pickedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', _pickedImage!.path),
      );
    } else if (_imageUrlController.text.isNotEmpty) {
      // Gunakan URL jika tidak ada file lokal
      request.fields['image_url'] = _imageUrlController.text;
    } else if (isEditMode) {
      // Jika dalam mode edit tanpa perubahan gambar
      request.fields['image_url'] = widget.photo!['image_url'];
    } else {
      throw Exception('Image or URL must be provided.');
    }

    // Kirim request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true); // Berhasil, kembali ke halaman sebelumnya
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(
          'Failed to save photo: ${errorResponse['error'] ?? response.body}');
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




  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('Close'),
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

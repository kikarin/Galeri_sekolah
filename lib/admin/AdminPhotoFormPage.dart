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
          ? 'http://192.168.137.19:8000/api/photos/${widget.photo!['id']}/update'
          : 'http://192.168.137.19:8000/api/photos';

      // Gunakan POST untuk update dan add (menghindari masalah PUT multipart)
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['gallery_id'] = widget.galleryId.toString();

      // Jika gambar dipilih, tambahkan file
      if (_pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // Nama field di Laravel
            _pickedImage!.path,
          ),
        );
      } else if (_imageUrlController.text.isNotEmpty) {
        request.fields['image_url'] = _imageUrlController.text;
      } else {
        throw Exception('Image or URL must be provided.');
      }

      // Kirim request dan dapatkan respons
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // Berhasil, kembali ke halaman sebelumnya
      } else {
        throw Exception('Failed to save photo: ${response.body}');
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
            ? Center(child: CircularProgressIndicator())
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
                        ? TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(labelText: 'Image URL'),
                            validator: (value) {
                              if (value!.isEmpty && _pickedImage == null) {
                                return 'Image URL or picked image is required';
                              }
                              return null;
                            },
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

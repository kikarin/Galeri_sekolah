import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool isLoading = false;
  bool isEditMode = false;

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

  Future<void> savePhoto() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final url = isEditMode
          ? 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/${widget.photo!['id']}'
          : 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos';

      final method = isEditMode ? 'PUT' : 'POST';

      final request = http.Request(method, Uri.parse(url))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'image_url': _imageUrlController.text,
          'gallery_id': widget.galleryId,
        });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        print('Failed to save photo');
      }

      setState(() {
        isLoading = false;
      });
    }
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(labelText: 'Image URL'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Image URL is required';
                        }
                        return null;
                      },
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminGalleryFormPage extends StatefulWidget {
  final Map<String, dynamic>? gallery;

  AdminGalleryFormPage({this.gallery});

  @override
  _AdminGalleryFormPageState createState() => _AdminGalleryFormPageState();
}

class _AdminGalleryFormPageState extends State<AdminGalleryFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  bool isLoading = false;
  bool isEditMode = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    loadUserId();
    if (widget.gallery != null) {
      isEditMode = true;
      _titleController.text = widget.gallery!['title'];
    }
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

Future<void> saveGallery() async {
  if (_formKey.currentState!.validate()) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID tidak ditemukan. Silakan login kembali.')),
      );
      return;
    }

      final url = isEditMode
          ? 'http://192.168.18.2:8000/api/galleries/${widget.gallery!['id']}'
          : 'http://192.168.18.2:8000/api/galleries';

      final method = isEditMode ? 'PUT' : 'POST';

      final request = http.Request(method, Uri.parse(url))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'title': _titleController.text,
          'user_id': userId,
        });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        print('Failed to save gallery');
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Gallery' : 'Add Gallery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
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
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveGallery,
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

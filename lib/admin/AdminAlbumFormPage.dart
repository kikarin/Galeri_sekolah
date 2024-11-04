import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini


class AdminAlbumFormPage extends StatefulWidget {
  final Map<String, dynamic>? album;

  AdminAlbumFormPage({this.album});

  @override
  _AdminAlbumFormPageState createState() => _AdminAlbumFormPageState();
}

class _AdminAlbumFormPageState extends State<AdminAlbumFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  int? userId;  // Ubah menjadi nullable untuk memastikan ini di-set sebelum digunakan

  @override
  void initState() {
    super.initState();
    loadUserId();
    if (widget.album != null) {
      _titleController.text = widget.album!['title'];
    }
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

 Future<void> saveAlbum() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID tidak ditemukan. Silakan login kembali.')),
      );
      return;
    }

    // Gunakan PUT untuk update, dan POST untuk create
    var response;
    if (widget.album == null) {
      response = await http.post(
        Uri.parse('http://192.168.137.19:8000/api/albums'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'user_id': userId  // Gunakan user_id yang dinamis
        }),
      );
    } else {
      response = await http.put(
        Uri.parse('http://192.168.137.19:8000/api/albums/${widget.album!['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'user_id': userId  // Gunakan user_id yang dinamis
        }),
      );
    }

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      final snackBar = SnackBar(content: Text('Failed to save album: ${response.body}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album == null ? 'Add Album' : 'Edit Album'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: saveAlbum,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

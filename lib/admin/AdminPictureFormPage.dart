// lib/pages/AdminPictureFormPage.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPictureFormPage extends StatefulWidget {
  final Map<String, dynamic>? picture;
  final int albumId;

  AdminPictureFormPage({this.picture, required this.albumId});

  @override
  _AdminPictureFormPageState createState() => _AdminPictureFormPageState();
}

class _AdminPictureFormPageState extends State<AdminPictureFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _imageUrlController = TextEditingController();
  bool isLoading = false;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.picture != null) {
      isEditMode = true;
      _imageUrlController.text = widget.picture!['image_url'];
    }
  }

  Future<void> savePicture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = isEditMode
          ? 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/pictures/${widget.picture!['id']}'
          : 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums/${widget.albumId}/pictures';

      final method = isEditMode ? 'PUT' : 'POST';

      var request = http.Request(method, Uri.parse(url));
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode({
        'image_url': _imageUrlController.text,
        'album_id': isEditMode ? null : widget.albumId,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
      } else {
        throw Exception(
            'Failed to save picture: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.picture == null ? 'Add Picture' : 'Edit Picture'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(labelText: 'Image URL'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an image URL.';
                        }
                        // Add additional URL validation here if needed
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : savePicture,
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

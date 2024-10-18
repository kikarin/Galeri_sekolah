import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminInfoFormPage extends StatefulWidget {
  final Map<String, dynamic>? info;

  AdminInfoFormPage({this.info});

  @override
  _AdminInfoFormPageState createState() => _AdminInfoFormPageState();
}

class _AdminInfoFormPageState extends State<AdminInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  bool isLoading = false;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.info != null) {
      isEditMode = true;
      _titleController.text = widget.info!['title'];
      _contentController.text = widget.info!['content'];
    }
  }

  Future<void> saveInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final url = isEditMode
          ? 'http://192.168.18.2:8000/api/infos/${widget.info!['id']}'
          : 'http://192.168.18.2:8000/api/infos';

      final method = isEditMode ? 'PUT' : 'POST';

      final response = await http.Request(method, Uri.parse(url))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'title': _titleController.text,
          'content': _contentController.text,
        });

      final streamedResponse = await response.send();
      final httpResponse = await http.Response.fromStream(streamedResponse);

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        print('Failed to save info');
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Info' : 'Add Info'),
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
                      controller: _contentController,
                      decoration: InputDecoration(labelText: 'Content'),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Content is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveInfo,
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

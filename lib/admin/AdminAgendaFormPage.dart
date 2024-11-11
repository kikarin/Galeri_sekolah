import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAgendaFormPage extends StatefulWidget {
  final Map<String, dynamic>? agenda;

  AdminAgendaFormPage({this.agenda});

  @override
  _AdminAgendaFormPageState createState() => _AdminAgendaFormPageState();
}

class _AdminAgendaFormPageState extends State<AdminAgendaFormPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  DateTime? _eventDate;
  bool isLoading = false;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.agenda != null) {
      isEditMode = true;
      _titleController.text = widget.agenda!['title'] ?? '';
      _descriptionController.text = widget.agenda!['description'] ?? '';
      if (widget.agenda!['event_date'] != null) {
        _eventDate = DateTime.parse(widget.agenda!['event_date']);
      }
    }
  }

  Future<void> _selectEventDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> saveAgenda() async {
  if (!_formKey.currentState!.validate() || _eventDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please ensure all fields are filled correctly.')),
    );
    return;
  }
  setState(() {
    isLoading = true;
  });

  // Mendeteksi apakah mode edit atau tambah baru
  final url = isEditMode
      ? 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/agendas/${widget.agenda!['id']}' // URL untuk edit
      : 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/agendas'; // URL untuk tambah baru

  // Pemilihan metode HTTP berdasarkan mode
  final response = isEditMode
      ? await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'event_date': _eventDate?.toIso8601String(),
          }),
        )
      : await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'event_date': _eventDate?.toIso8601String(),
          }),
        );

  setState(() {
    isLoading = false;
  });

  void deleteAgenda() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Deleting... Please wait.'),
          ],
        ),
      );
    },
  );

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final url = 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/agendas/${widget.agenda!['id']}';

  final response = await http.delete(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  Navigator.of(context).pop(); // Close the dialog

  if (response.statusCode == 200 || response.statusCode == 204) {
    Navigator.of(context).pop(); // Optionally close the form page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agenda deleted successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete agenda')),
    );
  }
}


  if (response.statusCode == 200 || response.statusCode == 201) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agenda saved successfully!')),
    );
  } else {
    print('Failed to save agenda: ${response.body}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save agenda. Please try again.')),
    );
    // Untuk debugging:
    debugPrint("HTTP Status: ${response.statusCode}, Body: ${response.body}");
  }
}


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Agenda' : 'Add Agenda'),
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
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    ListTile(
                      title: Text(_eventDate == null
                          ? 'Select Event Date'
                          : 'Event Date: ${_eventDate!.toLocal().toString().split(' ')[0]}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: _selectEventDate,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveAgenda,
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

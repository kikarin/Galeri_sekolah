import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminAgendaFormPage.dart'; // Impor halaman form Agenda

class AdminAgendaPage extends StatefulWidget {
  @override
  _AdminAgendaPageState createState() => _AdminAgendaPageState();
}

class _AdminAgendaPageState extends State<AdminAgendaPage> {
  List<dynamic> agendas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAgendas();
  }

  Future<void> fetchAgendas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('http://192.168.137.19:8000/api/agendas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sertakan header Authorization jika diperlukan
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        agendas = data;
        isLoading = false;
      });
    } else {
      print('Failed to load agendas');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteAgenda(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse('http://192.168.137.19:8000/api/agendas/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sertakan header Authorization jika diperlukan
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        agendas.removeWhere((agenda) => agenda['id'] == id);
      });
    } else {
      print('Failed to delete agenda');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Agendas'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAgendaFormPage()),
              );
              fetchAgendas();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : agendas.isEmpty
              ? Center(child: Text('No agendas available.'))
              : ListView.builder(
                  itemCount: agendas.length,
                  itemBuilder: (context, index) {
                    final agenda = agendas[index];
                    return ListTile(
                      title: Text(agenda['title']),
                      subtitle: Text("${agenda['description'] ?? 'No description'}\nEvent Date: ${agenda['event_date'] ?? 'No date'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminAgendaFormPage(
                                    agenda: agenda,
                                  ),
                                ),
                              );
                              fetchAgendas();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Confirm'),
                                  content: Text('Are you sure you want to delete this agenda?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        deleteAgenda(agenda['id']);
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

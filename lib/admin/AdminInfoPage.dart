import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'AdminInfoFormPage.dart'; // Impor halaman form Info

class AdminInfoPage extends StatefulWidget {
  @override
  _AdminInfoPageState createState() => _AdminInfoPageState();
}

class _AdminInfoPageState extends State<AdminInfoPage> {
  List<dynamic> infos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInfos();
  }

  Future<void> fetchInfos() async {
    // Ambil token dari SharedPreferences jika diperlukan
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('http://192.168.18.2:8000/api/infos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sertakan header Authorization jika diperlukan
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        infos = data;
        isLoading = false;
      });
    } else {
      print('Failed to load infos');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteInfo(int id) async {
    // Ambil token dari SharedPreferences jika diperlukan
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse('http://192.168.18.2:8000/api/infos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sertakan header Authorization jika diperlukan
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        infos.removeWhere((info) => info['id'] == id);
      });
    } else {
      print('Failed to delete info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Info'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              // Navigasi ke halaman form untuk menambah info baru
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminInfoFormPage()),
              );
              // Setelah kembali dari halaman form, refresh daftar info
              fetchInfos();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : infos.isEmpty
              ? Center(child: Text('Belum ada info.'))
              : ListView.builder(
                  itemCount: infos.length,
                  itemBuilder: (context, index) {
                    final info = infos[index];
                    return ListTile(
                      title: Text(info['title']),
                      subtitle: Text(info['content']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              // Navigasi ke halaman form untuk mengedit info
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminInfoFormPage(
                                    info: info,
                                  ),
                                ),
                              );
                              // Setelah kembali dari halaman form, refresh daftar info
                              fetchInfos();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Konfirmasi sebelum menghapus
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Konfirmasi'),
                                  content: Text('Apakah Anda yakin ingin menghapus info ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        deleteInfo(info['id']);
                                      },
                                      child: Text('Hapus'),
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'AdminGalleryFormPage.dart'; // Impor halaman form galeri
import 'AdminPhotoPage.dart'; // Impor halaman manajemen foto

class AdminGalleryPage extends StatefulWidget {
  @override
  _AdminGalleryPageState createState() => _AdminGalleryPageState();
}

class _AdminGalleryPageState extends State<AdminGalleryPage> {
  List<dynamic> galleries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGalleries();
  }

  Future<void> fetchGalleries() async {
    final response = await http.get(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/galleries'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        galleries = data;
        isLoading = false;
      });
    } else {
      print('Failed to load galleries');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteGallery(int id) async {
    final response = await http.delete(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/galleries/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        galleries.removeWhere((gallery) => gallery['id'] == id);
      });
    } else {
      print('Failed to delete gallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Galleries'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              // Navigasi ke halaman form untuk menambah galeri baru
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminGalleryFormPage()),
              );
              // Setelah kembali dari halaman form, refresh daftar galeri
              fetchGalleries();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: galleries.length,
              itemBuilder: (context, index) {
                final gallery = galleries[index];
                return ListTile(
                  title: Text(gallery['title']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () {
                          // Navigasi ke halaman manajemen foto dalam galeri ini
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminPhotoPage(galleryId: gallery['id']),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          // Navigasi ke halaman form untuk mengedit galeri
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminGalleryFormPage(
                                gallery: gallery,
                              ),
                            ),
                          );
                          // Setelah kembali dari halaman form, refresh daftar galeri
                          fetchGalleries();
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
                              content: Text('Apakah Anda yakin ingin menghapus galeri ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    deleteGallery(gallery['id']);
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

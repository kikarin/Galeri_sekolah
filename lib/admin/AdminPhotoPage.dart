import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AdminPhotoFormPage.dart';

class AdminPhotoPage extends StatefulWidget {
  final int galleryId;

  AdminPhotoPage({required this.galleryId});

  @override
  _AdminPhotoPageState createState() => _AdminPhotoPageState();
}

class _AdminPhotoPageState extends State<AdminPhotoPage> {
  List<dynamic> photos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPhotos();
  }

  Future<void> fetchPhotos() async {
    final response = await http.get(
      Uri.parse('http://192.168.18.2:8000/api/galleries/${widget.galleryId}/photos'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        photos = data;
        isLoading = false;
      });
    } else {
      print('Failed to load photos');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePhoto(int id) async {
    final response = await http.delete(
      Uri.parse('http://192.168.18.2:8000/api/photos/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        photos.removeWhere((photo) => photo['id'] == id);
      });
    } else {
      print('Failed to delete photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Photos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              // Navigasi ke halaman form untuk menambah foto baru
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminPhotoFormPage(galleryId: widget.galleryId),
                ),
              );
              // Setelah kembali dari halaman form, refresh daftar foto
              fetchPhotos();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return ListTile(
                  leading: Image.network(
                    photo['image_url'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(photo['title']),
                  subtitle: Text(photo['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          // Navigasi ke halaman form untuk mengedit foto
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminPhotoFormPage(
                                galleryId: widget.galleryId,
                                photo: photo,
                              ),
                            ),
                          );
                          // Setelah kembali dari halaman form, refresh daftar foto
                          fetchPhotos();
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
                              content: Text('Apakah Anda yakin ingin menghapus foto ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    deletePhoto(photo['id']);
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

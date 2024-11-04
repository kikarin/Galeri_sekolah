import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AdminAlbumFormPage.dart'; // Anda perlu membuat halaman form ini
import 'AdminPicturePage.dart';  // Pastikan Anda sudah membuat halaman ini


class AdminAlbumPage extends StatefulWidget {
  @override
  _AdminAlbumPageState createState() => _AdminAlbumPageState();
}

class _AdminAlbumPageState extends State<AdminAlbumPage> {
  List<dynamic> albums = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    final response = await http.get(
      Uri.parse('http://192.168.137.19:8000/api/albums'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        albums = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      print('Failed to load albums');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteAlbum(int id) async {
    final response = await http.delete(
      Uri.parse('http://192.168.137.19:8000/api/albums/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        albums.removeWhere((album) => album['id'] == id);
      });
    } else {
      print('Failed to delete album');
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Manage Albums'),
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminAlbumFormPage()),
          ).then((_) => fetchAlbums()), // Refresh list after adding/editing an album
        ),
      ],
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                title: Text(album['title']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo),
                      onPressed: () {
                        // Navigasi ke halaman manajemen foto dalam album ini
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPicturePage(albumId: album['id']),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminAlbumFormPage(album: album),
                        ),
                      ).then((_) => fetchAlbums()), // Refresh list after editing
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Confirm'),
                          content: Text('Are you sure you want to delete this album?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                deleteAlbum(album['id']);
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}

}

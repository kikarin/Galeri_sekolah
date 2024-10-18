// lib/pages/AdminPicturePage.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AdminPictureFormPage.dart';

class AdminPicturePage extends StatefulWidget {
  final int albumId;

  AdminPicturePage({required this.albumId});

  @override
  _AdminPicturePageState createState() => _AdminPicturePageState();
}

class _AdminPicturePageState extends State<AdminPicturePage> {
  List<dynamic> pictures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPictures();
  }

  Future<void> fetchPictures() async {
  var uri = Uri.parse('http://192.168.18.2:8000/api/albums/${widget.albumId}/pictures');
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_ACCESS_TOKEN', // Jika menggunakan autentikasi
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      pictures = jsonDecode(response.body);
      isLoading = false;
    });
  } else {
    print('Failed to load pictures');
    setState(() {
      isLoading = false;
    });
  }
}


  Future<void> deletePicture(int id) async {
  var uri = Uri.parse('http://192.168.18.2:8000/api/pictures/$id');
  final response = await http.delete(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_ACCESS_TOKEN', // Jika menggunakan autentikasi
    },
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    setState(() {
      pictures.removeWhere((picture) => picture['id'] == id);
    });
  } else {
    print('Failed to delete picture');
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Manage Pictures'),
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminPictureFormPage(albumId: widget.albumId)),
          ).then((_) => fetchPictures()), // Refresh list after adding/editing a picture
        ),
      ],
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: pictures.length,
            itemBuilder: (context, index) {
              final picture = pictures[index];
              return ListTile(
                leading: Image.network(
                  picture['image_url'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminPictureFormPage(picture: picture, albumId: widget.albumId),
                        ),
                      ).then((_) => fetchPictures()), // Refresh list after editing
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => deletePicture(picture['id']),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}

}

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

  String _resolveImageUrl(String imageUrl) {
    // Resolusi URL untuk gambar lokal atau remote
    if (imageUrl.startsWith('/storage')) {
      return 'https://ujikom2024pplg.smkn4bogor.sch.id$imageUrl';
    }
    return imageUrl;
  }

  Future<void> fetchPictures() async {
    setState(() {
      isLoading = true;
    });

    var uri = Uri.parse(
        'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums/${widget.albumId}/pictures');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          pictures = List<dynamic>.from(jsonDecode(response.body).map((picture) {
            picture['image_url'] = _resolveImageUrl(picture['image_url']);
            print('Resolved image URL: ${picture['image_url']}'); // Debugging
            return picture;
          }));
          isLoading = false;
        });
      } else {
        print('Failed to load pictures: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching pictures: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePicture(int id) async {
    var uri = Uri.parse(
        'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/pictures/$id');
    try {
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          pictures.removeWhere((picture) => picture['id'] == id);
        });
      } else {
        print('Failed to delete picture: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting picture: $e');
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
              MaterialPageRoute(
                  builder: (context) =>
                      AdminPictureFormPage(albumId: widget.albumId)),
            ).then((_) =>
                fetchPictures()), // Refresh list after adding a picture
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pictures.length,
              itemBuilder: (context, index) {
                final picture = pictures[index];
                final imageUrl = picture['image_url'] ?? '';
                print('Final Image URL: $imageUrl'); // Debugging

                return ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image,
                                size: 100, color: Colors.grey);
                          },
                        )
                      : Icon(Icons.image_not_supported, size: 100),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deletePicture(picture['id']),
                  ),
                );
              },
            ),
    );
  }
}

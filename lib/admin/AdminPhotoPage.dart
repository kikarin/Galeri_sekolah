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
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    fetchPhotos();
  }

  Future<void> fetchPhotos() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/galleries/${widget.galleryId}/photos'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          photos = data;
        });
      } else {
        showErrorDialog(
            'Failed to load photos. Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('An error occurred while fetching photos: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePhoto(int id) async {
    setState(() {
      isDeleting = true;
    });
    try {
      final response = await http.delete(
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          photos.removeWhere((photo) => photo['id'] == id);
        });
      } else {
        showErrorDialog(
            'Failed to delete photo. Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('An error occurred while deleting photo: $e');
    } finally {
      setState(() {
        isDeleting = false;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _resolveImageUrl(String imageUrl) {
    if (imageUrl.startsWith('/storage/')) {
      return 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public$imageUrl';
    }
    return imageUrl;
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdminPhotoFormPage(galleryId: widget.galleryId),
                ),
              );
              if (result == true) {
                fetchPhotos();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : photos.isEmpty
              ? Center(child: Text('No photos available.'))
              : ListView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final imageUrl = _resolveImageUrl(photo['image_url'] ?? '');

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.broken_image),
                                    )
                                  : Icon(Icons.image_not_supported),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photo['title'] ?? 'No Title',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (photo['description'] != null &&
                                      photo['description']!.isNotEmpty)
                                    Text(
                                      photo['description'] ?? '',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdminPhotoFormPage(
                                          galleryId: widget.galleryId,
                                          photo: photo,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      fetchPhotos();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Konfirmasi'),
                                        content: Text(
                                            'Apakah Anda yakin ingin menghapus foto ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

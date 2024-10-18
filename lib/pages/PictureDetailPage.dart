import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../helpers/web_downloader.dart' if (dart.library.io) '../helpers/mobile_downloader.dart';

class PictureDetailPage extends StatelessWidget {
  final String imageUrl;

  PictureDetailPage({required this.imageUrl});

  Future<void> downloadImageHandler(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await downloadImage(response.bodyBytes); // Platform otomatis
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image downloaded successfully!'),
            backgroundColor: Color(0xFF4A6FA5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download image.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("Failed to download image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picture Detail', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A6FA5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/images/loading.gif',
              image: imageUrl,
              fit: BoxFit.cover,
              imageErrorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => downloadImageHandler(context),
        backgroundColor: const Color(0xFF4A6FA5),
        child: const Icon(Icons.download, color: Colors.white),
      ),
    );
  }
}

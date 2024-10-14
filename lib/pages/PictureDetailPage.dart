import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class PictureDetailPage extends StatelessWidget {
  final String imageUrl;

  PictureDetailPage({required this.imageUrl});

  Future<void> downloadImageWeb(BuildContext context) async {
    try {
      var response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "DownloadedImage.jpg")
          ..click();

        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image downloaded successfully!'),
            backgroundColor: Color(0xFF4A6FA5), // Konsistensi warna dengan tema
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        title: Text('Picture Detail', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4A6FA5), // Konsistensi dengan BasePage
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
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
                return Center(
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => downloadImageWeb(context),
        backgroundColor: Color(0xFF4A6FA5), // Konsistensi warna FAB
        child: Icon(Icons.download, color: Colors.white),
      ),
    );
  }
}

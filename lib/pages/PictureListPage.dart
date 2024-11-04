import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart'; // Import shimmer package
import 'PictureDetailPage.dart';

class PictureListPage extends StatefulWidget {
  final int albumId;
  PictureListPage({required this.albumId});

  @override
  _PictureListPageState createState() => _PictureListPageState();
}

class _PictureListPageState extends State<PictureListPage> with SingleTickerProviderStateMixin {
  List pictures = [];
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchPictures();
  }

  Future<void> fetchPictures() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.137.19:8000/api/albums/${widget.albumId}/pictures'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pictures = data;
          isLoading = false;
        });
        _animationController.forward(); // Start animation after loading
      } else {
        _showSnackbar('Failed to load pictures', Colors.redAccent);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackbar('Error loading pictures', Colors.redAccent);
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pictures', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A6FA5),
      ),
      body: isLoading
          ? _buildShimmerLoader()
          : FadeTransition(
              opacity: _animationController,
              child: _buildPictureGrid(),
            ),
      backgroundColor: const Color(0xFFEBF1F6),
    );
  }

  // GridView with pictures
  Widget _buildPictureGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 4 / 3,
      ),
      itemCount: pictures.length,
      itemBuilder: (context, index) {
        final picture = pictures[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PictureDetailPage(imageUrl: picture['image_url']),
              ),
            );
          },
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildFadeInImage(picture['image_url']),
            ),
          ),
        );
      },
    );
  }

  // Shimmer loading skeleton
  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 4 / 3,
      ),
      itemCount: 6, // Skeleton placeholder count
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  // FadeInImage for smooth image loading
  Widget _buildFadeInImage(String imageUrl) {
    return FadeInImage.assetNetwork(
      placeholder: 'assets/images/loading.gif',
      image: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeInCurve: Curves.easeIn,
      imageErrorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

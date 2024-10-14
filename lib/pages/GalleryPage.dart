import 'package:flutter/material.dart';
import 'base_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'PhotoDetailPage.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool isLoading = true;
  List<dynamic> galleries = [];

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
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Gallery',
      currentIndex: 1,
      onNavItemTapped: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/gallery');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/user_info');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/user_agenda');
            break;
        }
      },
      body: isLoading
          ? _buildLoadingSkeleton()
          : galleries.isEmpty
              ? const Center(child: Text('No galleries available'))
              : _buildGalleryList(),
    );
  }

  Widget _buildGalleryList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final gallery = galleries[index];
                final photos = gallery['photos'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        gallery['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    photos != null && photos.isNotEmpty
                        ? _buildPhotoGrid(photos)
                        : Center(
                            child: Text(
                              'No photos available',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                    const SizedBox(height: 30),
                  ],
                );
              },
              childCount: galleries.length,
            ),
          ),
        ),
      ],
    );
  }

  // Grid photo yang lebih interaktif
  Widget _buildPhotoGrid(List<dynamic> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 4 / 3,
      ),
      itemCount: photos.length,
      itemBuilder: (context, photoIndex) {
        final photo = photos[photoIndex];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoDetailPage(photoId: photo['id']),
              ),
            );
          },
          child: Hero(
            tag: photo['id'],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _buildInteractivePhotoCard(photo),
            ),
          ),
        );
      },
    );
  }

  // Card photo yang lebih interaktif dengan efek hover dan glassmorphism
  Widget _buildInteractivePhotoCard(dynamic photo) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildPhotoImage(photo),
          ),
          _buildGlassmorphismOverlay(
              photo), // Overlay dengan efek glassmorphism
        ],
      ),
    );
  }

  // Membangun gambar dengan efek zoom saat hover
  // Membangun gambar tanpa pesan error (tetap kosong jika gambar gagal dimuat)
  // Membangun gambar dengan Shimmer saat loading dan tanpa error message saat gambar gagal dimuat
  Widget _buildPhotoImage(dynamic photo) {
    return Stack(
      children: [
        // Shimmer sebagai efek loading
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
          ),
        ),
        // Gambar yang diambil dari network
        Image.network(
          photo['image_url'], // URL gambar
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            // Tampilkan shimmer jika gambar masih dimuat
            if (loadingProgress == null) return child;
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[300],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Jika gambar gagal dimuat, tampilkan kotak kosong tanpa pesan error
            return Container(
              color: Colors.grey[200],
            );
          },
        ),
      ],
    );
  }

  // Overlay dengan efek glassmorphism dan informasi
  // Overlay dengan efek glassmorphism dan informasi
  Widget _buildGlassmorphismOverlay(dynamic photo) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        // Penting untuk membatasi area efek blur
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        child: BackdropFilter(
          // Menambahkan BackdropFilter di sini
          filter: ImageFilter.blur(
              sigmaX: 10, sigmaY: 10), // Efek blur glassmorphism
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 68, 100, 150),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    photo['title'] ?? 'No title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Skeleton loading dengan shimmer yang lebih modern
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 4 / 3,
        ),
        itemCount: 6,
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
      ),
    );
  }
}

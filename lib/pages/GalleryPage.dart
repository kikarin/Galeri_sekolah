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
  List<dynamic> filteredGalleries = []; 
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGalleries();
    searchController.addListener(_filterGalleries);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchGalleries() async {
    final response = await http.get(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/galleries'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        galleries = data..sort((a, b) {
          DateTime dateA = DateTime.parse(a['created_at']);
          DateTime dateB = DateTime.parse(b['created_at']);
          return dateB.compareTo(dateA); 
        });
        filteredGalleries = galleries;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterGalleries() {
    final keyword = searchController.text.toLowerCase();
    setState(() {
      filteredGalleries = galleries.where((gallery) {
        final title = gallery['title']?.toLowerCase() ?? '';
        return title.contains(keyword);
      }).toList();
    });
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
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading
                  ? _buildLoadingSkeleton()
                  : filteredGalleries.isEmpty
                      ? const Center(child: Text('No galleries available'))
                      : _buildGalleryList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getFullImageUrl(String imageUrl) {
  if (imageUrl.startsWith('/storage')) {
    return 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public$imageUrl';
  }
  return imageUrl; // Kembalikan URL asli jika sudah lengkap
}


  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Search Gallery',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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
                final gallery = filteredGalleries[index];
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
                          color: Colors.black87,
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
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                    const SizedBox(height: 30),
                  ],
                );
              },
              childCount: filteredGalleries.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(List<dynamic> photos) {
    photos.sort((a, b) {
      DateTime dateA = DateTime.parse(a['created_at']); 
      DateTime dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA); 
    });

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
        return InkWell(
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
            child: _buildInteractivePhotoCard(photo),
          ),
        );
      },
    );
  }

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
          _buildGlassmorphismOverlay(photo),
        ],
      ),
    );
  }

Widget _buildPhotoImage(dynamic photo) {
  final String imageUrl = _getFullImageUrl(photo['image_url'] ?? '');
  return Stack(
    children: [
      Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
        ),
      ),
      Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
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
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          );
        },
      ),
    ],
  );
}



  Widget _buildGlassmorphismOverlay(dynamic photo) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(150, 68, 100, 150),
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
                      overflow: TextOverflow.ellipsis,
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black38,
                        ),
                      ],
                    ),
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

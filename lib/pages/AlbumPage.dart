import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'PictureListPage.dart';

class AlbumPage extends StatefulWidget {
  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with SingleTickerProviderStateMixin {
  List albums = [];
  List filteredAlbums = [];
  final TextEditingController searchController = TextEditingController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchAlbums();
    searchController.addListener(_filterAlbums); // Listen to search input changes
  }

Future<void> fetchAlbums() async {
  try {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Sort albums by 'created_at' from newest to oldest
      data.sort((a, b) {
        DateTime dateA = DateTime.parse(a['created_at']);
        DateTime dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);  // Newest albums first
      });

      setState(() {
        albums = data;
        filteredAlbums = data; // Show all albums initially
      });
      _animationController.forward(); // Start animation when loaded
    } else {
      _showSnackbar('Failed to load albums', Colors.redAccent);
    }
  } catch (e) {
    _showSnackbar('Error loading albums', Colors.redAccent);
  }
}


  void _filterAlbums() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredAlbums = albums.where((album) {
        final titleLower = album['title'].toLowerCase();
        return titleLower.contains(query);
      }).toList();
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A6FA5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(child: _buildAlbumGrid()),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFEBF1F6), // Consistent background
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search albums...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF4A6FA5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF4A6FA5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF4A6FA5), width: 2),
        ),
      ),
    );
  }

  Widget _buildAlbumGrid() {
    if (filteredAlbums.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
      );
    }
    return FadeTransition(
      opacity: _animationController,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 4 / 3,
        ),
        itemCount: filteredAlbums.length,
        itemBuilder: (context, index) {
          final album = filteredAlbums[index];
          return _buildAlbumCard(album);
        },
      ),
    );
  }

  Widget _buildAlbumCard(Map album) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PictureListPage(albumId: album['id']),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          splashColor: const Color(0xFF4A6FA5).withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_album, size: 50, color: Color(0xFF4A6FA5)),
                const SizedBox(height: 10),
                Text(
                  album['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

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
      duration: Duration(milliseconds: 800),
    );
    fetchAlbums();
    searchController.addListener(_filterAlbums); // Listen to changes in the search field
  }

  Future<void> fetchAlbums() async {
    final response = await http.get(Uri.parse('http://192.168.18.2:8000/api/albums'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        albums = data;
        filteredAlbums = data; // Initially show all albums
      });
      _animationController.forward(); // Start animation after data is loaded
    } else {
      print('Failed to load albums');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Albums', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4A6FA5), // Matching BasePage theme
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search albums...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF4A6FA5)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Color(0xFF4A6FA5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Color(0xFF4A6FA5), width: 2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: filteredAlbums.isEmpty
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF4A6FA5)))
                  : FadeTransition(
                      opacity: _animationController,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 4 / 3,
                        ),
                        itemCount: filteredAlbums.length,
                        itemBuilder: (context, index) {
                          final album = filteredAlbums[index];
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Colors.black26,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                splashColor: Color(0xFF4A6FA5).withOpacity(0.3),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PictureListPage(albumId: album['id']),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_album, size: 50, color: Color(0xFF4A6FA5)),
                                      SizedBox(height: 10),
                                      Text(
                                        album['title'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87, // Consistent text color
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFFEBF1F6), // Matching BasePage background
    );
  }

  @override
  void dispose() {
    searchController.dispose(); // Dispose controller to avoid memory leaks
    _animationController.dispose();
    super.dispose();
  }
}

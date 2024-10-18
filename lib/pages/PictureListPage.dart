import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      duration: Duration(milliseconds: 800),
    );
    fetchPictures();
  }

  Future<void> fetchPictures() async {
    final response = await http.get(Uri.parse('http://192.168.18.2:8000/api/albums/${widget.albumId}/pictures'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        pictures = data;
        isLoading = false;
        _animationController.forward(); // Start animation when pictures are loaded
      });
    } else {
      print('Failed to load pictures');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pictures', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4A6FA5), // Konsisten dengan tema BasePage
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF4A6FA5)), // Sesuai tema
            )
          : FadeTransition(
              opacity: _animationController,
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/loading.gif',
                          image: picture['image_url'],
                          fit: BoxFit.cover,
                          fadeInDuration: Duration(milliseconds: 300),
                          fadeInCurve: Curves.easeIn,
                          imageErrorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      backgroundColor: Color(0xFFEBF1F6), // Konsisten dengan tema BasePage
    );
  }
}

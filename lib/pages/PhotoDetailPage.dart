import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class PhotoDetailPage extends StatefulWidget {
  final int photoId;

  PhotoDetailPage({required this.photoId});

  @override
  _PhotoDetailPageState createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  bool isLoading = true;
  Map<String, dynamic> photo = {};
  List<dynamic> comments = [];
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPhotoDetails();
  }

  Future<void> fetchPhotoDetails() async {
    final response = await http.get(
      Uri.parse(
          'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/${widget.photoId}'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        photo = data;
        comments = data['comments'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');
    final userName = prefs.getString('user_name');
    final commentText = commentController.text;

    if (commentText.isEmpty) {
      return;
    }

    if (token == null || userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final response = await http.post(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'photo_id': widget.photoId,
        'user_id': userId,
        'content': commentText,
      }),
    );

    if (response.statusCode == 201) {
      final newComment = jsonDecode(response.body)['comment'];
      newComment['user'] = {
        'id': userId,
        'name': userName ?? 'Anonim',
      };
      setState(() {
        comments.add(newComment);
        commentController.clear();
      });
    }
  }

  // Fungsi untuk memformat tanggal agar lebih pendek dan rapi
  String formatDate(String? dateString) {
    if (dateString == null) return 'Tidak tersedia';
    final DateTime parsedDate = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy')
        .format(parsedDate); // Contoh format: 01 Jan 2024
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
          title: Text(photo['title'] ?? 'Photo Detail'),
          backgroundColor: Color.fromARGB(255, 99, 130, 189)),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF5C6BC0)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isWideScreen
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _buildImage(photo['image_url'] ?? '')),
                              SizedBox(width: 20),
                              Expanded(child: _buildPhotoDetails()),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImage(photo['image_url'] ?? ''),
                              SizedBox(height: 20),
                              _buildPhotoDetails(),
                            ],
                          ),
                    SizedBox(height: 20),
                    Divider(thickness: 1.5, color: Colors.grey[300]),
                    Text(
                      'Komentar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 68, 100, 150),
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildCommentList(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  // Gambar utama dengan BoxFit.cover dan responsive height
  Widget _buildImage(String imageUrl) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: MediaQuery.of(context).size.width > 600 ? 400 : 300,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
                color: Color(0xFF5C6BC0),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
                child: Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ));
          },
        ),
      ),
    );
  }

  // Deskripsi dan informasi tambahan dari foto (tanggal saja, fotografer dihapus)
  Widget _buildPhotoDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photo['description'] ?? 'Deskripsi tidak tersedia',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Tanggal: ${formatDate(photo['created_at'])}', // Format tanggal diperbaiki
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // List Komentar dengan desain responsif
  Widget _buildCommentList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final userName =
            comment['user'] != null ? comment['user']['name'] : 'Anonim';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(
              userName[0].toUpperCase(),
              style: TextStyle(color: Colors.black),
            ),
          ),
          title: Text(comment['content']),
          subtitle: Text(userName),
        );
      },
      separatorBuilder: (context, index) {
        return Divider(color: Colors.grey[300]);
      },
    );
  }

  // Input Komentar dengan tata letak responsif
  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Tambahkan komentar...',
                labelStyle: TextStyle(color: Colors.grey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF5C6BC0)),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: sendComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 68, 100, 150), 
              shape: CircleBorder(),
              padding: EdgeInsets.all(14),
            ),
            child: Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

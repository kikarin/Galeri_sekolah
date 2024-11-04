import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  bool isLiked = false;
  int likeCount = 0;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPhotoDetails();
  }

  Future<void> fetchPhotoDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://192.168.137.19:8000/api/photos/${widget.photoId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          photo = data['photo'];
          comments = data['photo']['comments'] ?? [];
          likeCount = data['like_count'] ?? 0;
          isLiked = data['is_liked'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      await http.post(
        Uri.parse('http://192.168.137.19:8000/api/photos/${widget.photoId}/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
    }
  }

  Future<void> sendComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');
    final userName = prefs.getString('user_name');
    final commentText = commentController.text.trim();

    if (token == null || commentText.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.137.19:8000/api/comments'),
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
        newComment['user'] = {'id': userId, 'name': userName ?? 'Anonim'};
        setState(() {
          comments.add(newComment);
          commentController.clear();
        });
      }
    } catch (e) {
      print('Error while sending comment: $e');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.137.19:8000/api/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          comments.removeWhere((comment) => comment['id'] == commentId);
        });
      } else {
        print('Failed to delete comment: ${response.body}');
      }
    } catch (e) {
      print('Error while deleting comment: $e');
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tidak tersedia';
    final DateTime parsedDate = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return words[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(photo['title'] ?? 'Photo Detail'),
        backgroundColor: const Color(0xFF446496),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(photo['image_url'] ?? ''),
                  const SizedBox(height: 20),
                  _buildPhotoDetails(),
                  _buildLikeSection(),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 10),
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF446496),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCommentList(),
                ],
              ),
            ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPhotoDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          photo['description'] ?? 'Deskripsi tidak tersedia',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text('Tanggal: ${_formatDate(photo['created_at'])}'),
      ],
    );
  }

  Widget _buildLikeSection() {
    return Row(
      children: [
        InkWell(
          onTap: toggleLike,
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey,
            size: 30,
          ),
        ),
        const SizedBox(width: 10),
        Text('$likeCount likes'),
      ],
    );
  }

  Widget _buildCommentList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final userName = comment['user']['name'];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color.fromARGB(255, 55, 102, 160),
            child: Text(
              _getInitials(userName),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(comment['content']),
          subtitle: Text(userName),
          trailing: _buildDeleteIcon(comment['user']['id'], comment['id']),
        );
      },
      separatorBuilder: (context, index) => const Divider(),
    );
  }

  Widget _buildDeleteIcon(int? commentUserId, int commentId) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final loggedInUserId = snapshot.data?.getInt('user_id');
        if (loggedInUserId == commentUserId) {
          return IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteComment(commentId),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Tambahkan komentar...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: sendComment,
          ),
        ],
      ),
    );
  }
}

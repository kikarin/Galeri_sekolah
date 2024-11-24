import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';

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
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/${widget.photoId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          photo = data['photo'];
          photo['image_url'] = _getFullImageUrl(photo['image_url']); // Konversi URL lokal
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
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/photos/${widget.photoId}/like'),
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

  Future<void> editComment(int commentId, String newContent) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.put(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        setState(() {
          final commentIndex = comments.indexWhere((comment) => comment['id'] == commentId);
          if (commentIndex != -1) {
            comments[commentIndex]['content'] = newContent;
          }
        });
      } else {
        print('Failed to edit comment: ${response.body}');
      }
    } catch (e) {
      print('Error while editing comment: $e');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/comments/$commentId'),
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

  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('/storage')) {
      return 'https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public$imageUrl';
    } else if (imageUrl.startsWith('file:///storage')) {
      return 'https://ujikom2024pplg.smkn4bogor.sch.id' + imageUrl.replaceFirst('file://', '');
    }
    return imageUrl; // Kembalikan URL asli jika sudah lengkap
  }

  void _sharePhoto() {
    final shareContent = '${photo['title']}\n\n${photo['description']}\n\n${photo['image_url']}';
    Share.share(shareContent);
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
              child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showFullImage(context, photo['image_url'] ?? ''),
                    child: _buildImage(photo['image_url'] ?? ''),
                  ),
                  const SizedBox(height: 20),
                  _buildPhotoDetails(),
                  _buildActionSection(),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 10),
                  const Text(
                    'Komentar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF446496)),
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
    String fullImageUrl = _getFullImageUrl(imageUrl); // Gunakan URL lengkap
    return Container(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
      width: double.infinity,
      child: Image.network(
        fullImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
          ),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: BoxDecoration(color: Colors.black),
          ),
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

  Widget _buildActionSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        InkWell(
          onTap: toggleLike,
          child: Row(
            children: [
              Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 24),
              const SizedBox(width: 5),
              Text('$likeCount'),
            ],
          ),
        ),
        Row(
          children: [
            const Icon(Icons.comment, color: Colors.grey, size: 24),
            const SizedBox(width: 5),
            Text('${comments.length}'),
          ],
        ),
        InkWell(
          onTap: _sharePhoto,
          child: Row(
            children: [
              const Icon(Icons.share, color: Colors.grey, size: 24),
              const SizedBox(width: 5),
              const Text('Share'),
            ],
          ),
        ),
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
            backgroundColor: const Color.fromARGB(255, 55, 102, 160),
            child: Text(_getInitials(userName), style: const TextStyle(color: Colors.white)),
          ),
          title: Text(comment['content']),
          subtitle: Text(userName),
          trailing: _buildCommentActions(comment['user']['id'], comment['id'], comment['content']),
        );
      },
      separatorBuilder: (context, index) => const Divider(),
    );
  }

  Widget _buildCommentActions(int? commentUserId, int commentId, String currentContent) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final loggedInUserId = snapshot.data?.getInt('user_id');
        if (loggedInUserId == commentUserId) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditCommentDialog(commentId, currentContent),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteComment(commentId),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showEditCommentDialog(int commentId, String currentContent) {
    final TextEditingController editController = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Komentar'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(labelText: 'Edit your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty) {
                  editComment(commentId, newContent);
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
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
              decoration: const InputDecoration(labelText: 'Tambahkan komentar...'),
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

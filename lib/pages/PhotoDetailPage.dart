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
        Uri.parse('http://192.168.18.2:8000/api/photos/${widget.photoId}'),
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

        print('Fetched photo details: $data');
      } else {
        print('Failed to load photo details: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      print('Token is null. Please login first.');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      // Simpan nilai liked sebelumnya untuk menghindari perubahan status UI yang tidak konsisten.
      bool previousLikedState = isLiked;
      int previousLikeCount = likeCount;

      // Optimis: Ubah state UI sebelum respons.
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });

      final response = await http.post(
        Uri.parse('http://192.168.18.2:8000/api/photos/${widget.photoId}/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Jika API gagal, kembalikan state UI ke kondisi sebelumnya.
        setState(() {
          isLiked = previousLikedState;
          likeCount = previousLikeCount;
        });
        print(
            'Failed to toggle like: ${response.statusCode} - ${response.body}');
      } else {
        print('Like toggled successfully.');
      }
    } catch (e) {
      print('Error during like toggle: $e');

      // Jika terjadi error, kembalikan state UI ke kondisi sebelumnya.
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
    }
  }

Future<void> sendComment() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token'); // Ambil token untuk cek login
  final userId = prefs.getInt('user_id');
  final userName = prefs.getString('user_name');
  final commentText = commentController.text;

  if (token == null) {
    // Jika token tidak ada, pengguna belum login, arahkan ke halaman login
    print('User is not logged in. Redirecting to login page.');
    Navigator.pushReplacementNamed(context, '/login');
    return; // Kembalikan dari fungsi agar tidak melanjutkan eksekusi
  }

  if (commentText.isEmpty) return; // Jika komentar kosong, tidak lanjut

  try {
    final response = await http.post(
      Uri.parse('http://192.168.18.2:8000/api/comments'),
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
        commentController.clear(); // Bersihkan kolom input setelah komentar dikirim
      });
    } else {
      print('Failed to send comment: ${response.body}');
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
        Uri.parse('http://192.168.18.2:8000/api/comments/$commentId'),
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

  String formatDate(String? dateString) {
    if (dateString == null) return 'Tidak tersedia';
    final DateTime parsedDate = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(photo['title'] ?? 'Photo Detail'),
        backgroundColor: Color.fromARGB(255, 99, 130, 189),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF5C6BC0)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(photo['image_url'] ?? ''),
                    const SizedBox(height: 20),
                    _buildPhotoDetails(),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          onPressed: toggleLike,
                        ),
                        Text('$likeCount likes'),
                      ],
                    ),
                    Divider(thickness: 1.5, color: Colors.grey.shade300),
                    const Text(
                      'Komentar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 68, 100, 150),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCommentList(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      constraints: BoxConstraints(minHeight: 200, maxHeight: 300),
      width: double.infinity,
      child: Image.network(imageUrl, fit: BoxFit.cover),
    );
  }

  Widget _buildPhotoDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(photo['description'] ?? 'Deskripsi tidak tersedia'),
        const SizedBox(height: 10),
        Text('Tanggal: ${formatDate(photo['created_at'])}'),
      ],
    );
  }

  Widget _buildCommentList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return ListTile(
          title: Text(comment['content']),
          subtitle: Text(comment['user']['name']),
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
        if (!snapshot.hasData) return SizedBox.shrink();
        final loggedInUserId = snapshot.data?.getInt('user_id');
        if (loggedInUserId == commentUserId) {
          return IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteComment(commentId),
          );
        }
        return SizedBox.shrink();
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

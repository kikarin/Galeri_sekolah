import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'base_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  List<dynamic> infos = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchInfos();
  }

  Future<void> fetchInfos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://192.168.18.2:8000/api/infos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          infos = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _onNavItemTapped(int index) {
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
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Information',
      currentIndex: 2,
      onNavItemTapped: _onNavItemTapped,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF5C6BC0)))
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load info.',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchInfos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5C6BC0),
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : infos.isEmpty
                  ? Center(child: Text('No info available.'))
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: infos.length,
                      itemBuilder: (context, index) {
                        final info = infos[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    InfoDetailPage(info: info),
                              ),
                            );
                          },
                          child: InfoCard(info: info),
                        );
                      },
                    ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final dynamic info;

  InfoCard({required this.info});

  // Format tanggal agar lebih user-friendly
  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Unknown date';
    final DateTime dateTime = DateTime.parse(createdAt);
    return DateFormat.yMMMd().format(dateTime); // Format: "Jan 1, 2023"
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 68, 100, 150),
              Color.fromARGB(255, 136, 165, 219),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan judul info
            Text(
              info['title'] ?? 'No Title',
              style: GoogleFonts.robotoSlab(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Menampilkan tanggal created_at
            Text(
              'Created on: ${_formatDate(info['created_at'])}', // Tampilkan created_at
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70, // Warna teks lebih ringan
              ),
            ),
            SizedBox(height: 8),
            // Menampilkan konten info
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                info['content'] != null
                    ? (info['content'] as String).length > 100
                        ? info['content'].substring(0, 100) + '...'
                        : info['content']
                    : 'No Content',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Halaman Detail Info untuk melihat info lengkap dan created_at
class InfoDetailPage extends StatelessWidget {
  final dynamic info;

  InfoDetailPage({required this.info});

  // Format tanggal agar lebih user-friendly
  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Unknown date';
    final DateTime dateTime = DateTime.parse(createdAt);
    return DateFormat.yMMMMEEEEd()
        .format(dateTime); // Format: "Monday, January 1, 2023"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(info['title'] ?? 'Detail Info'),
        backgroundColor: Color(0xFF446496), // Cocokkan warna dengan BasePage
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tampilkan judul
            Text(
              info['title'] ?? 'No Title',
              style: GoogleFonts.robotoSlab(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF446496), // Cocokkan warna teks
              ),
            ),
            SizedBox(height: 16),
            // Tampilkan created_at
            Text(
              'Created on: ${_formatDate(info['created_at'])}', // Tampilkan created_at
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 16),
            // Tampilkan konten lengkap
            Text(
              info['content'] ?? 'No Content',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

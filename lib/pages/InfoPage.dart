import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  List<dynamic> filteredInfos = [];
  bool isLoading = true;
  bool hasError = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInfos();
    searchController.addListener(_filterInfos);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchInfos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/infos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Sort the info by 'created_at' from newest to oldest
        data.sort((a, b) {
          DateTime dateA = DateTime.parse(a['created_at']);
          DateTime dateB = DateTime.parse(b['created_at']);
          return dateB.compareTo(dateA); // Sort newest first
        });

        setState(() {
          infos = data;
          filteredInfos = infos; // Set filtered list as well
          isLoading = false;
          hasError = false;
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

  void _filterInfos() {
    final keyword = searchController.text.toLowerCase();
    setState(() {
      filteredInfos = infos.where((info) {
        final title = info['title']?.toLowerCase() ?? '';
        return title.contains(keyword);
      }).toList();
    });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Info',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : hasError
                      ? _buildErrorState()
                      : filteredInfos.isEmpty
                          ? Center(
                              child: Text(
                                'No info available.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredInfos.length,
                              itemBuilder: (context, index) {
                                final info = filteredInfos[index];
                                return Hero(
                                  tag: 'info_${info['id']}',
                                  child: InfoCard(info: info),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            'Failed to load info.',
            style: GoogleFonts.robotoSlab(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: fetchInfos,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6BC0),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final dynamic info;

  InfoCard({required this.info});

  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Unknown date';
    final DateTime dateTime = DateTime.parse(createdAt);
    return DateFormat.yMMMd().format(dateTime); // Format: "Jan 1, 2023"
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InfoDetailPage(info: info),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 68, 100, 150),
                Color.fromARGB(255, 136, 165, 219),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['title'] ?? 'No Title',
                style: GoogleFonts.robotoSlab(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Created on: ${_formatDate(info['created_at'])}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoDetailPage extends StatelessWidget {
  final dynamic info;

  InfoDetailPage({required this.info});

  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Unknown date';
    final DateTime dateTime = DateTime.parse(createdAt);
    return DateFormat.yMMMMEEEEd().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(info['title'] ?? 'Detail Info'),
        backgroundColor: const Color(0xFF446496),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info['title'] ?? 'No Title',
              style: GoogleFonts.robotoSlab(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF446496),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Created on: ${_formatDate(info['created_at'])}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info['content'] ?? 'No Content',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminGalleryPage.dart';
import 'AdminInfoPage.dart';
import 'AdminAgendaPage.dart';
import 'AdminAlbumPage.dart';
import 'AdminUserPage.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int userCount = 0;
  int galleryCount = 0;
  int infoCount = 0;
  int agendaCount = 0;
  int albumCount = 0;
  bool isLoading = true;
  String? _name;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchUserProfile(); // Ambil nama admin
  }

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    if (token != null && userId != null) {
      final response = await http.get(
        Uri.parse('http://192.168.18.2:8000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _name = data['name'];
        });
      }
    }
  }

  Future<void> fetchData() async {
    await Future.wait([
      fetchUserCount(),
      fetchGalleryCount(),
      fetchInfoCount(),
      fetchAgendaCount(),
      fetchAlbumCount(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserCount() async {
    final response = await http
        .get(Uri.parse('http://192.168.18.2:8000/api/users'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        userCount = data.where((user) => user['role'] == 'user').length;
      });
    }
  }

  Future<void> fetchGalleryCount() async {
    final response = await http
        .get(Uri.parse('http://192.168.18.2:8000/api/galleries'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        galleryCount = data.length;
      });
    }
  }

  Future<void> fetchInfoCount() async {
    final response = await http
        .get(Uri.parse('http://192.168.18.2:8000/api/infos'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        infoCount = data.length;
      });
    }
  }

  Future<void> fetchAgendaCount() async {
    final response = await http
        .get(Uri.parse('http://192.168.18.2:8000/api/agendas'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        agendaCount = data.length;
      });
    }
  }

  Future<void> fetchAlbumCount() async {
    final response = await http
        .get(Uri.parse('http://192.168.18.2:8000/api/albums'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        albumCount = data.length;
      });
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Color(0xFF4A6FA5), // Matching BasePage theme
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/admin_profile');
            },
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context), // Drawer modern
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildDashboardBody(context),
      backgroundColor: Color(0xFFEBF1F6), // Sesuai dengan warna background BasePage
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF4A6FA5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _name ?? 'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Dashboard Admin',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.photo_album, 'Manage Galleries',
              AdminGalleryPage()),
          _buildDrawerItem(context, Icons.info, 'Manage Info', AdminInfoPage()),
          _buildDrawerItem(
              context, Icons.event, 'Manage Agenda', AdminAgendaPage()),
          _buildDrawerItem(
              context, Icons.album, 'Manage Albums', AdminAlbumPage()),
          _buildDrawerItem(
              context, Icons.people, 'Manage Users', AdminUserPage()),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, dynamic page) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4A6FA5)),
      title: Text(title, style: TextStyle(fontSize: 18)),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
    );
  }

  Widget _buildDashboardBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildDashboardCard(
              context, 'Users', userCount, Icons.people, AdminUserPage()),
          _buildDashboardCard(context, 'Galleries', galleryCount,
              Icons.photo_album, AdminGalleryPage()),
          _buildDashboardCard(
              context, 'Info', infoCount, Icons.info, AdminInfoPage()),
          _buildDashboardCard(
              context, 'Agenda', agendaCount, Icons.event, AdminAgendaPage()),
          _buildDashboardCard(
              context, 'Albums', albumCount, Icons.album, AdminAlbumPage()),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, int count,
      IconData icon, dynamic page) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Color(0xFF4A6FA5)),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '$count',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }
}

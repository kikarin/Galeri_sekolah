import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    fetchData();
  }


  Future<void> fetchData() async {
    await fetchUserCount();
    await fetchGalleryCount();
    await fetchInfoCount();
    await fetchAgendaCount();
    await fetchAlbumCount();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserCount() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        userCount = data.where((user) => user['role'] == 'user').length;
      });
    }
  }

  Future<void> fetchGalleryCount() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/galleries'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        galleryCount = data.length;
      });
    }
  }

  Future<void> fetchInfoCount() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/infos'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        infoCount = data.length;
      });
    }
  }

  Future<void> fetchAgendaCount() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        agendaCount = data.length;
      });
    }
  }

  Future<void> fetchAlbumCount() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/albums'));
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

  // Drawer untuk admin menu
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A6FA5),
                  Color(0xFF65A1EA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              'Admin Name', // Bisa diganti dengan nama dinamis
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              'admin@example.com',
              style: TextStyle(fontSize: 16),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Color(0xFF4A6FA5)),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', '/admin_dashboard'),
          _buildDrawerItem(context, Icons.photo_album, 'Manage Galleries', AdminGalleryPage()),
          _buildDrawerItem(context, Icons.info, 'Manage Info', AdminInfoPage()),
          _buildDrawerItem(context, Icons.event, 'Manage Agenda', AdminAgendaPage()),
          _buildDrawerItem(context, Icons.album, 'Manage Albums', AdminAlbumPage()),
          _buildDrawerItem(context, Icons.people, 'Manage Users', AdminUserPage()),
        ],
      ),
    );
  }

  // Membuat item pada drawer dengan ikon dan teks
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, dynamic page) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4A6FA5)),
      title: Text(
        title,
        style: TextStyle(fontSize: 18),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
    );
  }

  // Body dari Admin Dashboard menggunakan Grid Icon Cards
  Widget _buildDashboardBody(BuildContext context) {
    // Menentukan jumlah kolom berdasarkan ukuran layar
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: crossAxisCount, // Responsif berdasarkan ukuran layar
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.photo_album,
            title: 'Manage Galleries',
            itemCount: galleryCount, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminGalleryPage())),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.info,
            title: 'Manage Info',
            itemCount: infoCount,  
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminInfoPage())),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.event,
            title: 'Manage Agenda',
            itemCount: agendaCount, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAgendaPage())),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.album,
            title: 'Manage Albums',
            itemCount: albumCount, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAlbumPage())),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.people,
            title: 'Manage Users',
            itemCount: userCount, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserPage())),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat Dashboard Card dengan gradasi dan warna sesuai tema
  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required int itemCount, required Function onTap}) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Color(0xFF4A6FA5), Color(0xFF65A1EA)], // Warna gradasi sesuai BasePage
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 5), // Bayangan lembut
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // Badge untuk jumlah item
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$itemCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

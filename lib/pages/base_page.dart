import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class BasePage extends StatefulWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavItemTapped;

  BasePage({
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onNavItemTapped,
  });

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage>
    with SingleTickerProviderStateMixin {
  String? _role;
  String? _name;
  String? _email;
  bool isLoadingProfile = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchUserProfile();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role');
    });
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    if (token != null && userId != null) {
      final response = await http.get(
        Uri.parse('http://192.168.137.19:8000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _name = data['name'];
          _email = data['email'];
          isLoadingProfile = false;
          prefs.setString('user_name', data['name']);
          prefs.setString('user_email', data['email']);
        });
      } else {
        setState(() {
          isLoadingProfile = false;
        });
      }
    } else {
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _role = null;
      _name = null;
      _email = null;
    });
    Navigator.pushReplacementNamed(context, '/login');
  }

// Fungsi untuk menampilkan SnackBar Custom yang lebih elegan dan sesuai tema
  void _showLoginRequiredNotification() {
    final snackBar = SnackBar(
      backgroundColor: Colors.transparent, // Membuat SnackBar transparan
      elevation: 0,
      duration: Duration(seconds: 4),
      content: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A6FA5),
              Color(0xFF65A1EA)
            ], // Warna sesuai tema BasePage
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Teks dengan Shadow yang lebih halus dan font yang tidak terlalu tebal
            Expanded(
              child: Text(
                "Anda perlu login untuk mengakses halaman ini.",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500, // Font tidak terlalu tebal
                  fontSize: 16, // Pastikan ukuran teks cukup besar
                  letterSpacing:
                      0.5, // Sedikit spasi antar huruf agar lebih rapi
                  shadows: [
                    Shadow(
                      blurRadius: 2.0, // Bayangan lebih halus
                      color: Colors.black38, // Warna bayangan lebih lembut
                      offset: Offset(1, 1), // Posisi bayangan lebih kecil
                    ),
                  ],
                ),
              ),
            ),
            // Tombol Login yang lebih stylish
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Warna latar belakang tombol
                foregroundColor: Color(0xFF4A6FA5), // Warna teks tombol
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600, // Font sedikit lebih tebal pada tombol
                  fontSize: 14, // Ukuran font yang lebih kecil di tombol
                ),
              ),
            ),
          ],
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Cek status login sebelum membuka halaman profile/album
  void _checkLoginStatusAndNavigate(String route) {
    if (_role == null) {
      _showLoginRequiredNotification();
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEBF1F6), // Abu-abu kebiruan
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _animationController,
        child: widget.body,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: Hero(
      tag: 'appBarTitle',
      child: Text(
        widget.title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 1.1,
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: Colors.black45,
              offset: Offset(1.5, 1.5),
            ),
          ],
        ),
      ),
    ),
    centerTitle: true,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 68, 100, 150),
            Color.fromARGB(255, 136, 165, 219),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    elevation: 6,
    shadowColor: Colors.black12,
    iconTheme: IconThemeData(color: Colors.white),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 10), // Sesuaikan padding kanan
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 19, 17, 17).withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: SizedBox(
                height: 30, // Atur tinggi tombol
                child: ElevatedButton(
                  onPressed: _role == null
                      ? () => Navigator.pushNamed(context, '/login')
                      : _logout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, // Kurangi padding agar tidak terlalu besar
                      vertical: 5,
                    ),
                    backgroundColor: Colors.transparent, // Transparan
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Sesuaikan ukuran tombol
                    children: [
                      Icon(
                        _role == null ? Icons.login : Icons.logout,
                        size: 18, // Sesuaikan ukuran ikon
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _role == null ? 'Login' : 'Logout',
                        style: const TextStyle(
                          fontSize: 14, // Font lebih kecil
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


  // Drawer dengan Profile
Widget _buildDrawer() {
  return Drawer(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 136, 165, 219),
            Color.fromARGB(255, 68, 100, 150)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/drawer_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            accountName: isLoadingProfile
                ? Text('Guest', style: TextStyle(fontSize: 18, color: Colors.black))
                : Text(_name ?? 'Guest User', style: TextStyle(fontSize: 18, color: Colors.black)),
            accountEmail: isLoadingProfile
                ? Text('guest@example.com', style: TextStyle(color: Colors.black))
                : Text(_email ?? 'Not logged in', style: TextStyle(color: Colors.black)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.black,
              child: _role != null
                  ? Icon(Icons.person, color: Colors.white, size: 40)
                  : Icon(Icons.person_outline, color: Colors.grey, size: 40),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Tampilkan Dashboard jika role adalah admin, jika tidak, tampilkan Home
                _role == 'admin'
                    ? _buildDrawerItem(Icons.dashboard, 'Dashboard', '/admin_dashboard')
                    : _buildDrawerItem(Icons.home, 'Home', '/home'),

                _buildDrawerItem(Icons.account_circle, 'My Profile', '/user_profile',
                    () => _checkLoginStatusAndNavigate('/user_profile')),
                _buildDrawerItem(Icons.photo_album, 'Gallery', '/gallery'),
                _buildDrawerItem(Icons.photo, 'Albums', '',
                    () => _checkLoginStatusAndNavigate('/albums')),
                _buildDrawerItem(Icons.info, 'Info', '/user_info'),
                _buildDrawerItem(Icons.event, 'Agenda', '/user_agenda'),

                if (_role != null)
                  _buildDrawerItem(Icons.exit_to_app, 'Logout', '', _logout),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  // Drawer item dengan hover
  Widget _buildDrawerItem(IconData icon, String title, String route,
      [Function()? onTap]) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      hoverColor: Colors.white.withOpacity(0.2),
      tileColor: Colors.white.withOpacity(0),
      onTap: onTap ?? () => Navigator.pushReplacementNamed(context, route),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  // Bottom Navigation Bar dengan Glassmorphic Effect
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Shadow lembut di navbar
            blurRadius: 10,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 15.0, sigmaY: 15.0), // Efek blur glassmorphism
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white
                .withOpacity(0.1), // Transparansi untuk glass effect
            elevation: 0,
            onTap: widget.onNavItemTapped,
            items: [
              _buildMagicNavItem(Icons.home, 'Home'),
              _buildMagicNavItem(Icons.photo_album, 'Gallery'),
              _buildMagicNavItem(Icons.info, 'Info'),
              _buildMagicNavItem(Icons.event, 'Agenda'),
            ],
            selectedItemColor: Color.fromARGB(255, 89, 127, 197),
            unselectedItemColor: const Color.fromARGB(179, 0, 0, 0),
            selectedLabelStyle:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildMagicNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [
              Color.fromARGB(255, 68, 100, 150),
              Color.fromARGB(255, 136, 165, 219)
            ], // Gradasi biru sesuai tema
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: Icon(icon, size: 30, color: Colors.white), // Warna default putih
      ),
      label: label,
    );
  }
}

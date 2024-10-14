import 'package:flutter/material.dart';
import 'pages/LoginPage.dart';
import 'pages/HomePage.dart';
import 'admin/AdminDashboard.dart';
import 'pages/user_profile_page.dart';
import 'admin/admin_Profile_page.dart';
import 'pages/GalleryPage.dart';
import 'pages/InfoPage.dart';
import 'pages/AgendaPage.dart';
import 'admin/AdminAlbumPage.dart';
import 'pages/AlbumPage.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        primaryColor: const Color(0xFFE8F1F2), // Warna utama aplikasi
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/login': (context) => LoginPage(), // LoginPage mencakup register mode
        '/home': (context) => HomePage(),
        '/admin_dashboard': (context) => AdminDashboard(),
        '/user_profile': (context) => UserProfilePage(),
        '/admin_profile': (context) => AdminProfilePage(),
        '/gallery': (context) => GalleryPage(),
        '/user_info': (context) => UserInfoPage(),
        '/user_agenda': (context) => UserAgendaPage(),
        '/admin_albums': (context) => AdminAlbumPage(),
        '/albums': (context) => AlbumPage(), // Route untuk AlbumPage
      },
    );
  }
}

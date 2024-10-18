import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'base_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoadingProfile = true;
// ignore: unused_field
String? _name;
// ignore: unused_field
String? _email;
  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
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
        final data = jsonDecode(response.body);
        if (data != null) {
          setState(() {
            _name = data['name'];
            _email = data['email'];
            isLoadingProfile = false;
          });
        }
      } else {
        setState(() {
          isLoadingProfile = false;
        });
      }
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
      title: 'Home',
      currentIndex: 0,
      onNavItemTapped: _onNavItemTapped,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWelcomeBanner(),
            SizedBox(height: 20),
            _buildFeaturedCarousel(screenWidth),
            SizedBox(height: 40),
            _buildNewsTicker(), // News Ticker
            SizedBox(height: 90),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // Welcome banner at the top
 Widget _buildWelcomeBanner() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 68, 100, 150),
          Color.fromARGB(255, 136, 165, 219)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'SMKN 4 Kota Bogor Gallery',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
            shadows: [
              Shadow(
                offset: Offset(1.5, 1.5),
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        SizedBox(height: 17),
        _buildAnimatedLogo(),  // Panggilan animasi logo
        SizedBox(height: 10),
        Text(
          'Jelajahi momen terbaik yang diabadikan oleh sekolah kami',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAnimatedLogo() {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: 1),
    duration: Duration(seconds: 2),
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: child,
      );
    },
    child: Image.asset(
      'images/LOGO.png',
      height: 100,
      width: 100,
    ),
  );
}


  // Featured Images Carousel
  Widget _buildFeaturedCarousel(double screenWidth) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        viewportFraction: 0.8,
      ),
      items: [
        'images/unnamed.jpg',
        'images/smkn4bogor_2.jpg',
        'images/maxresdefault.jpg'
      ].map((i) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: screenWidth,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  i,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // News ticker section
  Widget _buildNewsTicker() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 68, 100, 150),
            Color.fromARGB(255, 136, 165, 219),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 80,
        child: Stack(
          children: [
            // Lapisan untuk kerangka/stroke teks
            Align(
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2
                    ..color = Color.fromARGB(255, 68, 100, 150),
                ),
                child: _buildAnimatedText(),
              ),
            ),
            // Lapisan untuk isi teks (putih)
            Align(
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                child: _buildAnimatedText(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan teks animasi
  Widget _buildAnimatedText() {
    return AnimatedTextKit(
      animatedTexts: [
        RotateAnimatedText(
          'App Gallery Sekolah',
          textStyle: TextStyle(fontSize: 23),
          duration: Duration(milliseconds: 2000),
          rotateOut: true,
        ),
        RotateAnimatedText(
          'Info terkini terkait Gallery Sekolah!',
          textStyle: TextStyle(fontSize: 20),
          duration: Duration(milliseconds: 2000),
        ),
                TypewriterAnimatedText(
          'Want to join? Tinggal Login ya gess.. 😉',          
          textStyle: TextStyle(fontSize: 20),
          speed: Duration(milliseconds: 65),
          cursor: '|',
        ),
      ],
      repeatForever: true,
      pause: Duration(seconds: 1),
      displayFullTextOnTap: true,
    );
  }

  // Footer Section
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2024 SMKN 4 Kota Bogor',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(Icons.facebook, 'https://web.facebook.com/people/SMK-NEGERI-4-KOTA-BOGOR/100054636630766/'),
            SizedBox(width: 20),
            _buildSocialIcon(Icons.camera_alt, 'https://www.instagram.com/smkn4kotabogor/'),
            SizedBox(width: 20),
            _buildSocialIcon(Icons.web, 'https://smkn4bogor.sch.id/'),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Contact Us: info@smkn4bogor.sch.id',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      },
      child: Icon(
        icon,
        color: Colors.black.withOpacity(0.8),
        size: 30,
      ),
    );
  }
}

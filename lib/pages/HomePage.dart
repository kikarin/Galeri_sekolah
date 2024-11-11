import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoadingProfile = true;
  String? _name;
  String? _email;
  List<dynamic> galleryItems = [];
  List<dynamic> infoItems = [];
  List<dynamic> agendaItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchGalleryItems();
    _fetchInfoItems();
    _fetchAgendaItems();
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    if (token != null && userId != null) {
      final response = await http.get(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users/$userId'),
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

  Future<void> _fetchGalleryItems() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/galleries'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        galleryItems = (data as List).take(4).toList();
      });
    }
  }

  Future<void> _fetchInfoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/infos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        infoItems = (data as List).take(4).toList();
      });
    }
  }

  Future<void> _fetchAgendaItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/agendas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        agendaItems = (data as List).take(4).toList();
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
            _buildNewsTicker(),
            SizedBox(height: 40),
            _buildContentSections(),
          ],
        ),
      ),
    );
  }

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
          _buildAnimatedLogo(),
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
        'images/maxresdefault.jpg',
        'images/smkn4bogor_3.jpg'
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

  Widget _buildContentSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Gallery', galleryItems, '/gallery'),
        const SizedBox(height: 20),
        _buildSection('Info', infoItems, '/user_info'),
        const SizedBox(height: 20),
        _buildSection('Agenda', agendaItems, '/user_agenda'),
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic> items, String route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, route),
              child: const Text('Lihat Semua', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        items.isEmpty
            ? const Center(child: Text('Tidak ada konten tersedia'))
            : Column(
                children: items.map((item) {
                  return title == "Gallery" 
                      ? _buildGalleryItemCard(item) 
                      : title == "Info" 
                      ? _buildInfoItemCard(item) 
                      : _buildAgendaItemCard(item);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildGalleryItemCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Image.network(
          item['photos'][0]['image_url'] ?? '',
          fit: BoxFit.cover,
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 50),
        ),
        title: Text(item['title'] ?? 'No Title'),
        onTap: () => Navigator.pushNamed(context, '/gallery'),
      ),
    );
  }

  Widget _buildInfoItemCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(item['title'] ?? 'No Title'),
        subtitle: Text(
          item['content'] ?? 'No Content',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => Navigator.pushNamed(context, '/user_info'),
      ),
    );
  }

  Widget _buildAgendaItemCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(item['title'] ?? 'No Title'),
        subtitle: Text(
          item['description'] ?? 'No Description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => Navigator.pushNamed(context, '/user_agenda'),
      ),
    );
  }
}

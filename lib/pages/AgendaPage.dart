import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'base_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserAgendaPage extends StatefulWidget {
  @override
  _UserAgendaPageState createState() => _UserAgendaPageState();
}

class _UserAgendaPageState extends State<UserAgendaPage> {
  List<dynamic> agendas = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchAgendas();
  }

  Future<void> fetchAgendas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://192.168.18.2:8000/api/agendas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          agendas = data;
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
      print('Failed to load agendas: $e');
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
      title: 'Agenda',
      currentIndex: 3,
      onNavItemTapped: _onNavItemTapped,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF446496)))
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load agendas.',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchAgendas,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF446496),
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : agendas.isEmpty
                  ? Center(child: Text('No agendas available.'))
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: agendas.length,
                      itemBuilder: (context, index) {
                        final agenda = agendas[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AgendaDetailPage(agenda: agenda),
                              ),
                            );
                          },
                          child: AgendaCard(agenda: agenda),
                        );
                      },
                    ),
    );
  }
}

class AgendaCard extends StatelessWidget {
  final dynamic agenda;

  AgendaCard({required this.agenda});

  // Fungsi untuk format tanggal dari event_date
  String _formatDate(String? eventDate) {
    if (eventDate == null) return 'No Date';
    final DateTime dateTime = DateTime.parse(eventDate);
    return DateFormat.yMMMMd().format(dateTime); // Format: "January 1, 2023"
  }

  @override
  Widget build(BuildContext context) {
    final String title = agenda['title'] ?? 'No Title';
    final String description = agenda['description'] ?? 'No Description';
    final String eventDate = agenda['event_date'] ?? 'No Date';

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
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
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                description.length > 100
                    ? description.substring(0, 100) + '...'
                    : description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  "Date: ${_formatDate(eventDate)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Halaman Detail Agenda untuk melihat detail lengkap agenda
class AgendaDetailPage extends StatelessWidget {
  final dynamic agenda;

  AgendaDetailPage({required this.agenda});

  // Format tanggal
  String _formatDate(String? eventDate) {
    if (eventDate == null) return 'No Date';
    final DateTime dateTime = DateTime.parse(eventDate);
    return DateFormat.yMMMMEEEEd()
        .format(dateTime); // Format: "Monday, January 1, 2023"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(agenda['title'] ?? 'Detail Agenda'),
        backgroundColor: Color(0xFF446496),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agenda['title'] ?? 'No Title',
              style: GoogleFonts.robotoSlab(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF446496), // Cocokkan warna dengan BasePage
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Date: ${_formatDate(agenda['event_date'])}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 20),
            Text(
              agenda['description'] ?? 'No Description',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

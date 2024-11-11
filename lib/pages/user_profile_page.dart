import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isEditing = false;
  Map<String, dynamic> userData = {};
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    if (token == null || userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final response = await http.get(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userData = data;
        nameController.text = data['name'];
        emailController.text = data['email'];
        isLoading = false;
      });
      _animationController.forward(); // Start animation when data is loaded
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    final response = await http.put(
      Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': nameController.text,
        'email': emailController.text,
      }),
    );

    if (response.statusCode == 200) {
      final updatedData = jsonDecode(response.body);
      setState(() {
        userData = updatedData;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Color(0xFF4A6FA5), // Matching BasePage theme
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update profile!'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> checkIfLoggedInAndEditProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        backgroundColor: Color(0xFF4A6FA5), // Matching BasePage gradient theme
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: checkIfLoggedInAndEditProfile,
            )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4A6FA5)))
          : FadeTransition(
              opacity: _animationController,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: isEditing ? _buildEditForm() : _buildProfileView(),
              ),
            ),
      backgroundColor: Color(0xFFEBF1F6), // Matching BasePage background color
    );
  }

Widget _buildProfileView() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _buildProfileAvatar(), // Ganti dengan fungsi ini
      SizedBox(height: 20),
      _buildFullWidthProfileDetail("Name", userData['name'] ?? 'N/A'),
      SizedBox(height: 20),
      _buildFullWidthProfileDetail("Email", userData['email'] ?? 'N/A'),
      SizedBox(height: 40),
      ElevatedButton(
        onPressed: () => setState(() => isEditing = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A6FA5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
    ],
  );
}

// Fungsi Avatar Profil
Widget _buildProfileAvatar() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 20),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(2, 2),
        ),
      ],
    ),
    child: CircleAvatar(
      radius: 50,
      backgroundColor: const Color(0xFF4A6FA5),
      child: const Icon(Icons.person, size: 60, color: Colors.white),
    ),
  );
}

// Fungsi untuk Tampilan Detail Profil dengan Lebar Penuh
Widget _buildFullWidthProfileDetail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding samping
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A6FA5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, // Lebar penuh
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    ),
  );
}



  Widget _buildProfileDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A6FA5), // Matching BasePage text color
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: Color(0xFF4A6FA5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4A6FA5)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4A6FA5)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: Color(0xFF4A6FA5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4A6FA5)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4A6FA5)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A6FA5),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isEditing = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

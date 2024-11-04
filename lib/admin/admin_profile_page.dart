import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfilePage extends StatefulWidget {
  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool isLoading = true;
  bool isEditing = false;
  Map<String, dynamic> adminProfile = {};
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAdminProfile();
  }

  Future<void> fetchAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId =
        prefs.getInt('user_id'); // Pastikan ID ini sudah benar tersimpan

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
        adminProfile = data;
        isLoading = false;
        nameController.text = adminProfile['name'];
        emailController.text = adminProfile['email'];
      });
    } else {
      print(
          'Failed to load admin profile with status code: ${response.statusCode}');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');

    // Validasi password
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Passwords do not match!'),
      ));
      return;
    }

    // Buat body request dengan password baru hanya jika diisi
    final body = {
      'name': nameController.text,
      'email': emailController.text,
    };

    if (passwordController.text.isNotEmpty) {
      body['password'] = passwordController.text;
    }

    final response = await http.put(
      Uri.parse('http://192.168.137.19:8000/api/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final updatedData = jsonDecode(response.body);
      setState(() {
        adminProfile = updatedData;
        isEditing = false;
      });
    } else {
      print(
          'Failed to update profile with status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Profile"),
        backgroundColor: Color(0xFF4A6FA5),
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(20),
              child: isEditing ? _buildEditForm() : _buildProfileView(),
            ),
    );
  }

  // Tampilan profil (view mode)
  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Name: ${adminProfile['name']}",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text("Email: ${adminProfile['email']}", style: TextStyle(fontSize: 20)),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isEditing = true;
            });
          },
          child: Text("Edit Profile"),
        ),
      ],
    );
  }

  // Form untuk edit profil (edit mode)
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'New Password'),
          obscureText: true,
        ),
        TextField(
          controller: confirmPasswordController,
          decoration: InputDecoration(labelText: 'Confirm Password'),
          obscureText: true,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: updateProfile,
          child: Text("Save Changes"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isEditing = false;
            });
          },
          child: Text("Cancel"),
        ),
      ],
    );
  }
}

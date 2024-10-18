import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminUserPage extends StatefulWidget {
  @override
  _AdminUserPageState createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  List users = [];
  bool isLoading = true;
  bool isSubmitting = false; // Untuk tombol loading saat add/edit

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('http://192.168.18.2:8000/api/users'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        users = data.where((user) => user['role'] == 'user').toList();
        isLoading = false;
      });
    } else {
      showError('Failed to load users');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> showAddEditUserSheet({Map? user}) async {
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    final bool isEdit = user != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit User' : 'Add User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (!isEdit)
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
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (!isEdit && nameController.text.isEmpty) {
                          showError('Name is required');
                          return;
                        }
                        if (emailController.text.isEmpty) {
                          showError('Email is required');
                          return;
                        }
                        if (passwordController.text.isEmpty) {
                          showError('Password is required');
                          return;
                        }
                        await handleUserSubmission(
                          isEdit,
                          user?['id'],
                          nameController.text,
                          emailController.text,
                          passwordController.text,
                        );
                      },
                      child: Text(isEdit ? 'Update' : 'Add'),
                    ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> handleUserSubmission(
    bool isEdit,
    int? id,
    String name,
    String email,
    String password,
  ) async {
    setState(() => isSubmitting = true);
    final response = isEdit
        ? await http.put(
            Uri.parse('http://192.168.18.2:8000/api/users/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
        : await http.post(
            Uri.parse('http://192.168.18.2:8000/api/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': 'user',
            }),
          );

    setState(() => isSubmitting = false);
    Navigator.pop(context); // Tutup modal

    if (response.statusCode == 200 || response.statusCode == 201) {
      showSuccess(isEdit ? 'User updated successfully' : 'User added successfully');
      fetchUsers(); // Refresh list setelah operasi berhasil
    } else {
      showError('Failed to ${isEdit ? 'update' : 'add'} user');
    }
  }

  Future<void> deleteUser(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final response = await http.delete(
        Uri.parse('http://192.168.18.2:8000/api/users/$id'),
      );

      if (response.statusCode == 200) {
        showSuccess('User deleted successfully');
        fetchUsers();
      } else {
        showError('Failed to delete user');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => showAddEditUserSheet(),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => showAddEditUserSheet(user: user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteUser(user['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

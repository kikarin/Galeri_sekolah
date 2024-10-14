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

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final filteredUsers = data.where((user) => user['role'] == 'user').toList();
      setState(() {
        users = filteredUsers;
        isLoading = false;
      });
    } else {
      showError('Failed to load users');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

void showAddEditUserDialog(BuildContext context, {Map? user}) {
  TextEditingController nameController = TextEditingController(text: user != null ? user['name'] : '');
  TextEditingController emailController = TextEditingController(text: user != null ? user['email'] : '');
  TextEditingController passwordController = TextEditingController();
  bool isEdit = user != null;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit User' : 'Add User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!isEdit) // Only show the name field when adding a new user
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
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (isEdit) {
                updateUser(user!['id'], emailController.text, passwordController.text);
              } else {
                addUser(nameController.text, emailController.text, passwordController.text);
              }
              Navigator.of(context).pop();
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      );
    },
  );
}

void addUser(String name, String email, String password) async {
  final response = await http.post(
    Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'role': 'user'
    }),
  );
  if (response.statusCode == 201) {
    print('User added successfully.');
    fetchUsers(); // Refresh the list after adding a user
  } else {
    print('Failed to add user.');
  }
}

void updateUser(int id, String email, String password) async {
  final response = await http.put(
    Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password
    }),
  );
  if (response.statusCode == 200) {
    print('User updated successfully.');
    fetchUsers(); // Refresh the list after updating a user
  } else {
    print('Failed to update user.');
  }
}


  void deleteUser(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              final response = await http.delete(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0059495358/backend/public/api/users/$id'));
              if (response.statusCode == 200) {
                fetchUsers();
                showError('User deleted successfully.');
              } else {
                showError('Failed to delete user.');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => showAddEditUserDialog(context),
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
                        onPressed: () => showAddEditUserDialog(context, user: user),
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

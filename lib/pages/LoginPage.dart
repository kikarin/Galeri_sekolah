import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool isLoginMode = true;
  bool isPasswordVisible = false; // Track password visibility
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.18.2:8000/api/login'),
        body: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String role = data['user']['role'];
        final String token = data['access_token'];
        final int userId = data['user']['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        await prefs.setString('auth_token', token);
        await prefs.setInt('user_id', userId);

        Navigator.pushReplacementNamed(context, role == 'admin' ? '/admin_dashboard' : '/home');
      } else {
        setState(() {
          errorMessage = 'Login failed. Check your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error occurred. Try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.18.2:8000/api/register'),
        body: {
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          errorMessage = 'Registration failed. Please check your inputs.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error occurred. Try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF446496)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF446496), Color(0xFF88A5DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'images/7309682.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 30),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      width: screenWidth * 0.85,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: isLoginMode ? buildLoginForm() : buildRegisterForm(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isLoginMode = !isLoginMode;
                        });
                      },
                      child: Text(
                        isLoginMode
                            ? "Don't have an account? Register here"
                            : "Already have an account? Login here",
                        style: TextStyle(color: Color.fromARGB(255, 59, 59, 59), fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoginForm() {
    return Column(
      key: ValueKey(1),
      children: [
        Text(
          'Login Account',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF446496)),
        ),
        SizedBox(height: 30),
        buildEmailPasswordFields(),
        SizedBox(height: 20),
        buildActionButton('Login', login),
      ],
    );
  }

  Widget buildRegisterForm() {
    return Column(
      key: ValueKey(2),
      children: [
        Text(
          'Create Your Account',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF446496)),
        ),
        SizedBox(height: 30),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your name';
            return null;
          },
        ),
        SizedBox(height: 20),
        buildEmailPasswordFields(),
        SizedBox(height: 20),
        buildActionButton('Register', register),
      ],
    );
  }

  Widget buildEmailPasswordFields() {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          ),
          validator: (value) {
            if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          ),
          validator: (value) {
            if (value == null || value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget buildActionButton(String text, Function onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onPressed(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF446496),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(text, style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}

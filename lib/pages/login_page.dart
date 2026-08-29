import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  final _idFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String selectedRole = "Student";
  bool obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final inputId = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (inputId.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Please fill in all fields.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? accountEmail;

      // 1. If user typed a direct email, use it; otherwise perform Firestore ID lookup
      if (inputId.contains('@')) {
        accountEmail = inputId;
      } else {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('userCodeId', isEqualTo: inputId)
            .where('role', isEqualTo: selectedRole)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          _showErrorSnackBar("No $selectedRole account found with ID: $inputId");
          return;
        }

        accountEmail = userQuery.docs.first.data()['email'] as String?;
      }

      if (accountEmail == null || accountEmail.isEmpty) {
        _showErrorSnackBar("Could not locate email associated with this account.");
        return;
      }

      // 2. Sign in with mapped email and password
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: accountEmail,
        password: password,
      );

      final user = userCredential.user;

      // 3. Enforce Email Verification for Students
      if (selectedRole == "Student" && user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showErrorSnackBar(
          "Email not verified. Please verify your email before logging in.",
        );
        return;
      }

      if (!mounted) return;

      // 4. Navigate to main attendance page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AttendancePage(
            courseName: "Project 250",
            isTeacher: selectedRole == "Teacher",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = "Invalid ID or password.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Please try again later.";
          break;
        default:
          errorMessage = e.message ?? "Authentication failed.";
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: SvgPicture.asset(
                    'assets/icon_white.svg',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Attendance Tracker",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 28),

                // Simple Role Selection Segmented Control
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: "Student",
                      label: Text("Student"),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: "Teacher",
                      label: Text("Teacher"),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedRole = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // ID Input Field
                TextField(
                  controller: _idController,
                  focusNode: _idFocusNode,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: selectedRole == "Student"
                        ? "Student ID"
                        : "Teacher ID",
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _handleLogin(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Switch to Signup Page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
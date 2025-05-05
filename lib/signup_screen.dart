import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart'; // Import the main screen

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // To show a loading indicator

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text == _confirmPasswordController.text) {
        setState(() {
          _isLoading = true; // Start loading
        });
        try {
          final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (userCredential.user != null) {
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'username': _usernameController.text.trim(),
              'location': _locationController.text.trim(),
              'email': _emailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(), // Add timestamp
              'profileImageUrl': '', // Initial profile image URL
              'rating': 0.0, // Initial rating
              'reviewCount': 0, // Initial review count
            });

            // Optionally send email verification
            await userCredential.user!.sendEmailVerification();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Signup successful! Please verify your email.')),
            );

            // Navigate to the main screen with a slight delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              }
            });
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to create user account.')),
              );
            }
          }
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'Signup failed: ';
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage += 'The email address is already in use by another account.';
              break;
            case 'invalid-email':
              errorMessage += 'The email address is not valid.';
              break;
            case 'weak-password':
              errorMessage += 'The password is too weak.';
              break;
            default:
              errorMessage += 'An error occurred during signup.';
              break;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        } catch (e) {
          print('Unexpected signup error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An unexpected error occurred.')),
            );
          }
        } finally {
          setState(() {
            _isLoading = false; // Stop loading
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(
                  child: Text(
                    'Create an Account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your email'
                      : (value.contains('@')
                      ? null
                      : 'Please enter a valid email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter username'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter location'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter password'
                      : (value.length < 6
                      ? 'Password must be at least 6 characters'
                      : null),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Confirm password'
                      : (value != _passwordController.text
                      ? 'Passwords do not match'
                      : null),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup, // Disable button while loading
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
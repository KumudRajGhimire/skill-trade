import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _username;
  String? _location;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?; // Explicit cast
          if (userData != null) {
            setState(() {
              _username = userData['username'] as String?;
              _location = userData['location'] as String?;
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load user profile data.')),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load user profile.')),
          );
        }
      } catch (e) {
        print('Error loading profile: $e');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user profile.')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in.')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Directly navigate to the LoginScreen using pushReplacement
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to logout. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 60), // Placeholder for profile image
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Username',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(_username ?? 'Not available', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(_location ?? 'Not available', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            // You can add more profile information or actions here
          ],
        ),
      ),
    );
  }
}
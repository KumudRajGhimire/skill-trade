import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation

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
  String? _email;
  String? _bio;
  double _rating = 0.0;
  int _reviewCount = 0;
  bool _isLoading = true;

  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  final int _bioCharacterLimit = 40;

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
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            setState(() {
              _username = userData['username'] as String?;
              _location = userData['location'] as String?;
              _email = userData['email'] as String?;
              _bio = userData['bio'] as String?;
              _rating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
              _reviewCount = (userData['reviewCount'] as num?)?.toInt() ?? 0;
              _bioController.text = _bio ?? ''; // Initialize bio controller
              _isLoading = false;
            });
          } else {
            _showSnackBar('Could not load user profile data.');
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          _showSnackBar('Could not load user profile.');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
        _showSnackBar('Failed to load user profile.');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showSnackBar('No user logged in.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _updateBio() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final trimmedBio = _bioController.text.trim();
      if (trimmedBio.length <= _bioCharacterLimit) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'bio': trimmedBio,
          });
          setState(() {
            _bio = trimmedBio; // Update the displayed bio
            _isEditingBio = false;
          });
          _showSnackBar('Bio updated successfully!');
        } catch (e) {
          print('Error updating bio: $e');
          _showSnackBar('Failed to update bio. Please try again.');
        }
      } else {
        _showSnackBar('Bio cannot exceed $_bioCharacterLimit characters.');
      }
    } else {
      _showSnackBar('No user logged in.');
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      _showSnackBar('Failed to logout. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Stack(
                children: [
                  const CircleAvatar( // Replace with NetworkImage later
                    radius: 60,
                    child: Icon(Icons.person, size: 70),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.edit, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                _username ?? 'Not available',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber[400]),
                  const SizedBox(width: 2),
                  Text('$_rating', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 5),
                  Text('($_reviewCount reviews)', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 15),
            if (_bio != null && !_isEditingBio)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center( // Using Center to align bio text
                  child: Text(
                    _bio!,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 2, // To handle longer bios gracefully
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (_isEditingBio)
              TextFormField(
                controller: _bioController,
                maxLength: _bioCharacterLimit,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter your bio (max $_bioCharacterLimit characters)...',
                  counterText: '${_bioController.text.length} / $_bioCharacterLimit',
                  counterStyle: TextStyle(
                    color: _bioController.text.length > _bioCharacterLimit ? Colors.red : null,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // To update the counter
                },
              ),
            const SizedBox(height: 8),
            Center(
              child: _isEditingBio
                  ? ElevatedButton(
                onPressed: _updateBio,
                child: const Text('Save Bio'),
              )
                  : TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingBio = true;
                  });
                },
                child: Text(
                  _bio?.isNotEmpty == true ? 'Edit Bio' : 'Add Bio',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.grey),
                const SizedBox(width: 5),
                Text(_location ?? 'Not available', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, color: Colors.grey),
                const SizedBox(width: 5),
                Text(_email ?? 'Not available', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Set background color to red
                  foregroundColor: Colors.white, // Set text color to white
                ),
                child: const Text('Sign Out'),
              ),
            ),
            // Add more profile information or actions here
          ],
        ),
      ),
    );
  }
}
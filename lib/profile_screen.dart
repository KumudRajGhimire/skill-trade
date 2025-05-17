import 'dart:io'; // For File

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation
import 'gig_details_screen.dart'; // Import GigDetailsScreen for navigation
import 'edit_gig_screen.dart'; // Import EditGigScreen for editing gigs

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional userId for viewing other profiles

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _username;
  String? _location;
  String? _email;
  double _rating = 0.0;
  int _reviewCount = 0;
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final String? targetUserId = widget.userId ?? _currentUserId;

    if (targetUserId != null) {
      try {
        final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(targetUserId).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            setState(() {
              _username = userData['username'] as String?;
              _location = userData['location'] as String?;
              _email = userData['email'] as String?;
              _rating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
              _reviewCount = (userData['reviewCount'] as num?)?.toInt() ?? 0;
              _profileImageUrl = userData['assets/default_profile.png'] as String?;
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
      _showSnackBar('No user ID provided.');
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

  Widget _buildGigTile(String title, VoidCallback onTap, {VoidCallback? onEdit}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        onTap: onTap,
        trailing: onEdit != null
            ? IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
        )
            : null,
      ),
    );
  }

  Widget _buildGigColumn(
      String title, Stream<QuerySnapshot> stream, bool isEditable) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white),);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white,));
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No gigs available',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final gigDoc = snapshot.data!.docs[index];
                      final gigData = gigDoc.data() as Map<String, dynamic>;
                      final gigTitle = gigData['title'] ?? 'Unnamed Gig';

                      return _buildGigTile(
                        gigTitle,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GigDetailsScreen(gig: gigData),
                          ),
                        ),
                        onEdit: isEditable
                            ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditGigScreen(
                              gigData: gigData,
                              gigId: gigDoc.id,
                            ),
                          ),
                        )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String defaultProfileImage = 'assets/default_profile.png'; // Use String instead of AssetImage
    final isCurrentUserProfile = widget.userId == null || widget.userId == _currentUserId;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(isCurrentUserProfile ? 'Your Profile' : '${_username ?? 'User'}\'s Profile', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.grey[800],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white,))
          : Column(
        children: [
          // Profile Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage(defaultProfileImage) as ImageProvider<Object>,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _username ?? 'User Name',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_rating',
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              Text(
                                ' ($_reviewCount reviews)',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70,),
                              const SizedBox(width: 4),
                              Text(
                                _location ?? 'Location',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 16, color: Colors.white70,),
                              const SizedBox(width: 4),
                              Text(
                                _email ?? 'Email',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Gigs Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (isCurrentUserProfile)
                    _buildGigColumn(
                      'Gigs You Have Accepted',
                      FirebaseFirestore.instance
                          .collection('gigs')
                          .where('acceptedByUserId', isEqualTo: _currentUserId)
                          .where('status', whereIn: ['accepted', 'working', 'completed'])
                          .snapshots(),
                      false,
                    ),
                  _buildGigColumn(
                    'Your Posted Gigs',
                    FirebaseFirestore.instance
                        .collection('gigs')
                        .where('postedBy', isEqualTo: widget.userId ?? _currentUserId)
                        .snapshots(),
                    isCurrentUserProfile,
                  ),
                ],
              ),
            ),
          ),
          // Sign Out Button
          if (isCurrentUserProfile)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: const Text('Sign Out', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}
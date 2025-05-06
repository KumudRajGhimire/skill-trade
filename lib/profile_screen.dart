import 'dart:io'; // For File

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'gig_details_screen.dart'; // Import GigDetailScreen for navigation
import 'edit_gig_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Add this parameter

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
  String? _bio;
  double _rating = 0.0;
  int _reviewCount = 0;
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _currentUserId; // To check if it's the current user's profile

  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  final int _bioCharacterLimit = 40;
  final ImagePicker _picker = ImagePicker();

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
    final String? targetUserId = widget.userId ?? _currentUserId; // Use passed userId or current user's

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
              _bio = userData['bio'] as String?;
              _rating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
              _reviewCount = (userData['reviewCount'] as num?)?.toInt() ?? 0;
              _profileImageUrl = userData['profileImageUrl'] as String?;
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

  Future<void> _uploadProfileImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });
      File imageFile = File(pickedFile.path);
      final User? user = _auth.currentUser;
      if (user != null) {
        final String fileName = path.basename(imageFile.path);
        final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(user.uid)
            .child(fileName);

        try {
          await ref.putFile(imageFile);
          final String downloadURL = await ref.getDownloadURL();
          await _firestore.collection('users').doc(user.uid).update({
            'profileImageUrl': downloadURL,
          });
          setState(() {
            _profileImageUrl = downloadURL;
            _isLoading = false;
          });
          _showSnackBar('Profile picture updated!');
        } catch (e) {
          print('Error uploading image: $e');
          _showSnackBar('Failed to upload profile picture.');
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
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Profile Picture From'),
          actions: <Widget>[
            TextButton(
              child: const Text('Gallery'),
              onPressed: () {
                Navigator.of(context).pop();
                _uploadProfileImage(ImageSource.gallery);
              },
            ),
            TextButton(
              child: const Text('Camera'),
              onPressed: () {
                Navigator.of(context).pop();
                _uploadProfileImage(ImageSource.camera);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

  Widget _buildGigListItem(BuildContext context, DocumentSnapshot doc) {
    final gigData = doc.data() as Map<String, dynamic>?;
    final title = gigData?['title'] as String? ?? 'No Title';
    final status = gigData?['status'] as String? ?? 'Posted';
    final postedBy = gigData?['postedBy'] as String?;
    final isCurrentUserPoster = postedBy == _currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(title),
        subtitle: Text('Status: $status'),
        onTap: () async {
          // Fetch the gig data using the ID
          final gigSnapshot = await FirebaseFirestore.instance.collection('gigs').doc(doc.id).get();
          if (gigSnapshot.exists && gigSnapshot.data() != null) {
            final fullGigData = gigSnapshot.data() as Map<String, dynamic>;
            fullGigData['id'] = doc.id;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GigDetailsScreen(gig: fullGigData),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load gig details.')),
            );
          }
        },
        trailing: isCurrentUserPoster
            ? IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            // Fetch the full gig data to pass to the edit screen
            final gigSnapshot = await FirebaseFirestore.instance.collection('gigs').doc(doc.id).get();
            if (gigSnapshot.exists && gigSnapshot.data() != null) {
              final fullGigData = gigSnapshot.data() as Map<String, dynamic>;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGigScreen(
                    gigData: fullGigData,
                    gigId: doc.id,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not load gig for editing.')),
              );
            }
          },
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUserProfile = widget.userId == null || widget.userId == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUserProfile ? 'Your Profile' : '${_username ?? 'User'}\'s Profile'),
      ),
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
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const Icon(Icons.person, size: 70) as ImageProvider?,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 70)
                        : null,
                  ),
                  if (isCurrentUserProfile) // Show edit icon only for current user
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerDialog,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
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
            if (isCurrentUserProfile) // Show bio editing only for current user
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
            if (isCurrentUserProfile) // Show bio edit/save button only for current user
              Center(
                child: _isEditingBio
                    ? ElevatedButton(
                  onPressed: _updateBio,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Increased padding
                    textStyle: const TextStyle(fontSize: 16), // Optional: Increased font size
                  ),
                  child: const Text('Save Bio'),
                )
                    : TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingBio = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Increased padding
                    textStyle: const TextStyle(fontSize: 16), // Optional: Increased font size
                  ),
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
            const SizedBox(height: 20),

            // Section for Gigs Accepted by Current User
            if (isCurrentUserProfile)
              Text('Gigs You\'ve Accepted', style: Theme.of(context).textTheme.titleMedium),
            if (isCurrentUserProfile)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('gigs')
                    .where('acceptedBy', isEqualTo: _currentUserId)
                    .where('status', whereIn: ['accepted', 'working', 'completed'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error loading accepted gigs: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Text('No gigs accepted yet.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // To avoid nested scrolling issues
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return _buildGigListItem(context, snapshot.data!.docs[index]);
                    },
                  );
                },
              ),
            if (isCurrentUserProfile) const SizedBox(height: 20),

            // Section for Gigs Posted by Current User
            Text(
              isCurrentUserProfile ? 'Your Posted Gigs' : '${_username ?? 'User'}\'s Posted Gigs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gigs')
                  .where('postedBy', isEqualTo: widget.userId ?? _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error loading posted gigs: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Text(isCurrentUserProfile ? 'You haven\'t posted any gigs yet.' : 'No gigs posted by this user.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return _buildGigListItem(context, snapshot.data!.docs[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 30),
            if (isCurrentUserProfile) // Show logout button only for current user
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
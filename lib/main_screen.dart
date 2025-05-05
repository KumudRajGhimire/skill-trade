import 'package:flutter/material.dart';
import 'post_gig_screen.dart'; // Import the PostGigScreen
import 'profile_screen.dart'; // Import the ProfileScreen
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For more icons (optional, but good for community chat)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // To manage bottom navigation if needed

  void _navigateToPostGig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostGigScreen()),
    );
  }

  void _navigateToHome() {
    // TODO: Implement navigation to the home feed/screen
    print('Navigate to Home');
    setState(() {
      _selectedIndex = 0; // If using bottom navigation
    });
  }

  void _navigateToCommunityChat() {
    // TODO: Implement navigation to the community chat screen
    print('Navigate to Community Chat');
    setState(() {
      _selectedIndex = 2; // If using bottom navigation
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillTrade Home'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to SkillTrade!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'You are now logged in.',
              style: TextStyle(fontSize: 16),
            ),
            // Add other homepage widgets here
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPostGig,
        child: const Icon(Icons.add, size: 36), // Big plus icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: _navigateToHome,
            ),
            const SizedBox(width: 48.0), // Space for the FAB
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline), // Using Flutter's built-in chat icon
              onPressed: _navigateToCommunityChat,
            ),
          ],
        ),
      ),
    );
  }
}
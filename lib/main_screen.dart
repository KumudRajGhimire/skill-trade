import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_gig_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart'; // Ensure this file defines HomeScreen
import 'notifications_screen.dart'; // Ensure this is the correct import
import 'chats_overview_screen.dart'; // Import the new screen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _newGigPosted = false;
  bool _hasUnreadNotifications = false; // Add this line

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications(); // Call it here
  }

  void _navigateToPostGig() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostGigScreen(onGigPosted: _markGigAsPosted),
      ),
    );
    if (result == true) {
      _markGigAsPosted(); // Ensure flag is set if pop with true
    }
  }

  void _markGigAsPosted() {
    setState(() {
      _newGigPosted = true;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0 && _newGigPosted) {
        _newGigPosted = false; // Reset the flag
      }
      if (_selectedIndex == 3) {
        _hasUnreadNotifications = false; // Remove the indicator if navigate to notifications
      }
    });
  }

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // Ensure HomeScreen is properly defined
    const ChatsOverviewScreen(), // Use the new screen here
    const SizedBox(), // Placeholder for Post Gig
    const NotificationsScreen(), // Ensure correct NotificationsScreen is imported
    const ProfileScreen(),
  ];

  Future<void> _checkUnreadNotifications() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserUid)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _hasUnreadNotifications = snapshot.docs.isNotEmpty;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.black, // Set the background color of the BottomAppBar to black
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.home_outlined,
                color: _selectedIndex == 0 ? Colors.white : Colors.white38,
              ),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: _selectedIndex == 1 ? Colors.white : Colors.white38,
              ),
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 40, color: Colors.white),
              onPressed: _navigateToPostGig,
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: _selectedIndex == 3 ? Colors.white : Colors.white38,
                  ),
                  onPressed: () => _onItemTapped(3),
                ),
                if (_hasUnreadNotifications) // Use the boolean variable
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: _selectedIndex == 4 ? Colors.white : Colors.white38,
              ),
              onPressed: () => _onItemTapped(4),
            ),
          ],
        ),
      ),
    );
  }
}
// main_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_gig_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'chats_overview_screen.dart'; // Import the new screen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _newGigPosted = false;

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
    });
  }

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // HomeScreen will handle its own loading and refreshing
    const ChatsOverviewScreen(), // Use the new screen here
    const SizedBox(), // Placeholder for Post Gig
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0
            ? const Text('Available Gigs')
            : _selectedIndex == 1
            ? const Text('Chats')
            : _selectedIndex == 3
            ? const Text('Notifications')
            : _selectedIndex == 4
            ? const Text('Profile')
            : const Text('Home'),
        automaticallyImplyLeading: false,
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.home_outlined,
                color: _selectedIndex == 0 ? Theme.of(context).primaryColor : null,
              ),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 40),
              onPressed: _navigateToPostGig,
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => _onItemTapped(3),
                ),
                if (currentUserUid != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('recipientId', isEqualTo: currentUserUid)
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      return hasUnread
                          ? Positioned(
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
                      )
                          : const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: _selectedIndex == 4 ? Theme.of(context).primaryColor : null,
              ),
              onPressed: () => _onItemTapped(4),
            ),
          ],
        ),
      ),
    );
  }
}
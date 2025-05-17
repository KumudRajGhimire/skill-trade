import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatsOverviewScreen extends StatelessWidget {
  const ChatsOverviewScreen({super.key});

  Future<String> _getUsername(String userId) async {
    try {
      final DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userSnapshot.exists && userSnapshot.data() != null) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        return userData['username'] as String? ?? 'User';
      }
      return 'User'; // Default if username not found
    } catch (e) {
      print('Error fetching username: $e');
      return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    const defaultProfileImage = AssetImage('assets/default_profile.png');

    if (currentUserId == null) {
      return const Center(child: Text('Please log in to view chats.', style: TextStyle(color: Colors.white70)));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.black, // Darker app bar
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active chats.', style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = (chatData['participants'] as List<dynamic>?)?.cast<String>() ?? [];
              final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');

              return FutureBuilder<String>(
                future: _getUsername(otherUserId),
                builder: (context, usernameSnapshot) {
                  String otherUsername = 'User'; // Default value

                  if (usernameSnapshot.connectionState == ConnectionState.done) {
                    otherUsername = usernameSnapshot.data ?? 'User';
                  } else if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                    otherUsername = 'Loading...'; // Or some other loading indicator
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                    builder: (context, userSnapshot) {
                      String? profileImageUrl;
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final otherUserData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        profileImageUrl = otherUserData?['profileImageUrl'] as String?;
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(otherUserId: otherUserId),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[800], // Darker chat tile
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blueAccent, width: 2),
                                ),
                                child: CircleAvatar(
                                  backgroundImage: profileImageUrl != null && profileImageUrl.startsWith('http')
                                      ? NetworkImage(profileImageUrl)
                                      : defaultProfileImage,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  otherUsername,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white70),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
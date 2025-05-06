// chats_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatsOverviewScreen extends StatelessWidget {
  const ChatsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    print('Current User ID: $currentUserId'); // Debugging

    if (currentUserId == null) {
      return const Center(child: Text('Please log in to view chats.'));
    }

    return Scaffold(

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Firestore Stream Error: ${snapshot.error}'); // Debugging
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            print('No chats found for user: $currentUserId'); // Debugging
            return const Center(child: Text('No active chats.'));
          }

          print('Number of chats found: ${snapshot.data!.docs.length}'); // Debugging

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = (chatData['participants'] as List<dynamic>?)?.cast<String>() ?? [];
              final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
              print('Chat ID: ${chatDoc.id}, Participants: $participants, Other User ID: $otherUserId'); // Debugging

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final otherUserData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    final otherUsername = otherUserData?['username'] as String? ?? 'User';
                    final profileImageUrl = otherUserData?['profileImageUrl'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : const AssetImage('assets/default_profile.png') as ImageProvider?, // Replace with your default asset
                        ),
                        title: Text(
                          otherUsername,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(otherUserId: otherUserId),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Chat with User (ID: $otherUserId)'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(otherUserId: otherUserId),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
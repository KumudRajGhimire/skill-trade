// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markNotificationAsRead(BuildContext context, String notificationId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notification as read.')),
        );
      }
    }
  }

  Future<void> _deleteNotification(BuildContext context, String notificationId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted.')),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification.')),
        );
      }
    }
  }

  void _openChat(BuildContext context, String otherUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(otherUserId: otherUserId),
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context, String otherUserId, String otherUsername, String notificationId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Start Chat?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you want to start a chat with "$otherUsername"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _markNotificationAsRead(context, notificationId).then((_) {
                  _openChat(context, otherUserId);
                });
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: currentUserUid == null
          ? const Center(child: Text('Please log in to see notifications.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserUid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final data = document.data() as Map<String, dynamic>;
              final notificationType = data['type'];
              final notificationId = document.id;
              final isRead = data['read'] as bool? ?? false;

              if (notificationType == 'interest') {
                final senderUsername = data['senderUsername'] as String? ?? 'Unknown User';
                final gigTitle = data['gigTitle'] as String? ?? 'Unknown Gig';
                final senderId = data['senderId'] as String?;
                final timestamp = data['timestamp'] as Timestamp?;
                final dateTime = timestamp?.toDate();
                final formattedTime = dateTime != null ? '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}' : '';
                final formattedDate = dateTime != null ? '${dateTime.day}/${dateTime.month}/${dateTime.year}' : '';

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  color: isRead ? Colors.grey[200] : null,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: senderUsername,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' has shown interest in your gig: "'),
                          TextSpan(
                            text: gigTitle,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const TextSpan(text: '"'),
                        ],
                      ),
                    ),
                    subtitle: Text('$formattedTime - $formattedDate'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isRead)
                          const Icon(Icons.circle, color: Colors.blueAccent, size: 16),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteNotification(context, notificationId),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (senderId != null && senderUsername.isNotEmpty) {
                        _showConfirmationDialog(context, senderId, senderUsername, notificationId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not start chat. Sender information missing.')),
                        );
                      }
                    },
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          );
        },
      ),
    );
  }
}
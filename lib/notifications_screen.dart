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
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark notification as read.')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted.')),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete notification.')),
      );
    }
  }

  Future<void> _updateNotificationStatus(
      BuildContext context,
      String notificationId,
      String updatedStatus,
      String gigId,
      String senderId,
      String gigTitle,
      ) async {
    try {
      // Update the original notification's status
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'status': updatedStatus});

      if (updatedStatus == 'confirmed') {
        // Update the gigs collection to set acceptedByUserId and status
        final gigRef = FirebaseFirestore.instance.collection('gigs').doc(gigId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(gigRef);
          if (!snapshot.exists) {
            throw Exception("Gig does not exist!");
          }
          final gigData = snapshot.data() as Map<String, dynamic>;
          if (gigData['acceptedByUserId'] == null) {
            transaction.update(gigRef, {
              'acceptedByUserId': senderId,
              'status': 'accepted',
              'acceptedDate': FieldValue.serverTimestamp(),
            });
          } else if (gigData['acceptedByUserId'] != senderId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This gig has already been accepted by someone else.')),
            );
            return; // Stop further notification if already accepted by someone else
          }
        });
      }

      // Send a new notification to the sender based on the updated status
      String notificationMessage = updatedStatus == 'confirmed'
          ? 'Your request for gig "$gigTitle" has been confirmed.'
          : 'Your request for gig "$gigTitle" has been rejected.';

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': senderId,
        'type': updatedStatus, // "confirmed" or "rejected"
        'gigId': gigId,
        'gigTitle': notificationMessage,
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'senderUsername': 'Gig Poster',
        'status': updatedStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $updatedStatus successfully!')),
      );
    } catch (e) {
      print('Error updating notification status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update request status. Please try again.')),
      );
    }
  }

  void _openChat(String senderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(otherUserId: senderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[900], // Black background
      body: currentUserUid == null
          ? const Center(child: Text('Please log in to see notifications.', style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserUid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.', style: TextStyle(color: Colors.white)));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final data = document.data() as Map<String, dynamic>;
              final notificationId = document.id;
              final isRead = data['read'] as bool? ?? false;
              final type = data['type'] as String? ?? '';
              final status = data['status'] as String? ?? '';
              final gigTitle = data['gigTitle'] as String? ?? 'No Title';
              final senderId = data['senderId'] as String? ?? '';
              final senderUsername = data['senderUsername'] as String? ?? 'Unknown User';
              final gigId = data['gigId'] as String? ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();
              final formattedTime = dateTime != null
                  ? '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'
                  : '';
              final formattedDate = dateTime != null
                  ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
                  : '';

              if (type == 'request') {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  color: isRead ? Colors.grey[800] : Colors.grey[700], // Darker card colors
                  child: ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: Colors.white70),
                    title: Text('$senderUsername wants to accept your gig "$gigTitle".', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('$formattedTime - $formattedDate', style: const TextStyle(color: Colors.grey)),
                    trailing: status == 'pending'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _updateNotificationStatus(
                            context,
                            notificationId,
                            'confirmed',
                            gigId,
                            senderId,
                            gigTitle,
                          ),
                          child: const Text('Confirm', style: TextStyle(color: Colors.green)), // Keep original color
                        ),
                        TextButton(
                          onPressed: () => _updateNotificationStatus(
                            context,
                            notificationId,
                            'rejected',
                            gigId,
                            senderId,
                            gigTitle,
                          ),
                          child: const Text('Reject', style: TextStyle(color: Colors.red)), // Keep original color
                        ),
                      ],
                    )
                        : Text(
                      status == 'confirmed' ? 'Confirmed' : 'Rejected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'confirmed' ? Colors.green : Colors.red, // Keep original color
                      ),
                    ),
                    onTap: () {
                      _markNotificationAsRead(notificationId);
                      if (senderId.isNotEmpty) {
                        _openChat(senderId); // Open chat for gig requests
                      }
                    },
                  ),
                );
              } else if (type == 'confirmed' || type == 'rejected') {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  color: isRead ? Colors.grey[800] : Colors.grey[700], // Darker card colors
                  child: ListTile(
                    leading: Icon(
                      type == 'confirmed'
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: type == 'confirmed' ? Colors.green : Colors.red, // Keep original color
                    ),
                    title: Text(gigTitle, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('$formattedTime - $formattedDate', style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      onPressed: () => _deleteNotification(notificationId),
                    ),
                    onTap: () => _markNotificationAsRead(notificationId),
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
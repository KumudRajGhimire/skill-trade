// gig_details_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GigDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> gig;

  const GigDetailsScreen({super.key, required this.gig});

  Future<void> _sendInterestNotification(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final interestedUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final interestedUsername = interestedUserDoc.data()?['username'];
        final posterUserId = gig['postedBy'];

        if (posterUserId != user.uid) { // Don't notify yourself
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': posterUserId,
            'type': 'interest',
            'gigId': gig['id'],
            'gigTitle': gig['title'],
            'senderId': user.uid,
            'senderUsername': interestedUsername,
            'timestamp': DateTime.now(),
            'read': false,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your interest has been sent to the poster!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot express interest in your own gig.')),
          );
        }
      } catch (e) {
        print('Error sending interest notification: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send interest. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to express interest.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(gig['title'] as String? ?? 'Gig Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              gig['title'] as String? ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Posted by: ${gig['postedByUsername'] as String? ?? 'Anonymous'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              gig['description'] as String? ?? 'No Description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            const Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.work_outline, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Offering: ${gig['offeringSkill'] as String? ?? 'Not specified'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.search_outlined, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Looking for: ${gig['desiredSkill'] as String? ?? 'Not specified'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Location: ${gig['location'] as String? ?? 'Not specified'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money_outlined, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  gig['gigType'] == 'Trade'
                      ? 'Type: Trade'
                      : gig['payment'] != null
                      ? 'Payment: ₹${gig['payment']}'
                      : 'Type: Free',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _sendInterestNotification(context),
              child: const Text('Express Interest'),
            ),
            // You can add more details or actions here
          ],
        ),
      ),
    );
  }
}
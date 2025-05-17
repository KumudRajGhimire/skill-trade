import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rating_screen.dart'; // Import the RatingScreen

class GigDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> gig;

  const GigDetailsScreen({super.key, required this.gig});

  @override
  State<GigDetailsScreen> createState() => _GigDetailsScreenState();
}

class _GigDetailsScreenState extends State<GigDetailsScreen> {
  bool _isRequesting = false;
  bool _isMarkingAsDone = false; // Added loading indicator for marking as done

  Future<void> _sendRequestToAcceptGig(BuildContext context) async {
    setState(() {
      _isRequesting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final requesterDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final requesterUsername = requesterDoc.data()?['username'];
        final posterUserId = widget.gig['postedBy'];

        if (posterUserId != user.uid) { // Ensure the user is not requesting their own gig
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': posterUserId,
            'type': 'request',
            'gigId': widget.gig['id'],
            'gigTitle': widget.gig['title'],
            'senderId': user.uid,
            'senderUsername': requesterUsername,
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your request has been sent to the gig poster.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot request to accept your own gig.')),
          );
        }
      } catch (e) {
        print('Error sending request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send request. Please try again.')),
        );
      } finally {
        setState(() {
          _isRequesting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send a request.')),
      );
      setState(() {
        _isRequesting = false;
      });
    }
  }

  Future<void> _markGigAsDone(BuildContext context) async {
    setState(() {
      _isMarkingAsDone = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    final gigPosterId = widget.gig['postedBy'];

    if (currentUser != null) {
      try {
        // Update the gig status to 'completed'
        print('Gig ID: ${widget.gig['id']}');
        await FirebaseFirestore.instance.collection('gigs').doc(widget.gig['id']).update({
          'status': 'completed',
        });

        // Send a notification to the gig poster
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientId': gigPosterId,
          'type': 'gig_completed',
          'gigId': widget.gig['id'],
          'gigTitle': widget.gig['title'],
          'senderId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gig marked as done! The poster has been notified.')),
        );
      } catch (e) {
        print('Error marking gig as done: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark gig as done. Please try again.')),
        );
      } finally {
        setState(() {
          _isMarkingAsDone = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.')),
      );
      setState(() {
        _isMarkingAsDone = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final postedByUserId = widget.gig['postedBy'];
    final acceptedByUserId = widget.gig['acceptedByUserId'];
    final status = widget.gig['status'];

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Darker app bar
        title: Text(
          widget.gig['title'] as String? ?? 'Gig Details',
          style: const TextStyle(color: Colors.white), // White title text
        ),
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.gig['title'] as String? ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white), // White text
            ),
            const SizedBox(height: 10),
            Text(
              'Posted by: ${widget.gig['postedByUsername'] as String? ?? 'Anonymous'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), // White text
            ),
            const SizedBox(height: 8),
            Text(
              widget.gig['description'] as String? ?? 'No Description',
              style: const TextStyle(fontSize: 16, color: Colors.white70), // Lighter text
            ),
            const SizedBox(height: 15),
            const Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), // White text
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.work_outline, color: Colors.grey[400]), // Lighter icon
                const SizedBox(width: 5),
                Text('Offering: ${widget.gig['offeringSkill'] as String? ?? 'Not specified'}', style: const TextStyle(color: Colors.white70)), // Lighter text
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.search_outlined, color: Colors.grey[400]), // Lighter icon
                const SizedBox(width: 5),
                Text('Looking for: ${widget.gig['desiredSkill'] as String? ?? 'Not specified'}', style: const TextStyle(color: Colors.white70)), // Lighter text
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey[400]), // Lighter icon
                const SizedBox(width: 5),
                Text('Location: ${widget.gig['location'] as String? ?? 'Not specified'}', style: const TextStyle(color: Colors.white70)), // Lighter text
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money_outlined, color: Colors.grey[400]), // Lighter icon
                const SizedBox(width: 5),
                Text(
                  widget.gig['gigType'] == 'Trade'
                      ? 'Type: Trade'
                      : widget.gig['payment'] != null
                      ? 'Payment: ₹${widget.gig['payment']}'
                      : 'Type: Free',
                  style: const TextStyle(color: Colors.white70), // Lighter text
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (currentUser != null && currentUser.uid != postedByUserId && acceptedByUserId == null && status != 'accepted') ...[
              ElevatedButton(
                onPressed: _isRequesting ? null : () => _sendRequestToAcceptGig(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700], // Darker button color
                  foregroundColor: Colors.white, // White text color
                ),
                child: _isRequesting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)), // White indicator
                )
                    : const Text('Request to Accept'),
              ),
            ],
            if (acceptedByUserId == currentUser?.uid && status == 'accepted')
              ElevatedButton(
                onPressed: _isMarkingAsDone ? null : () => _markGigAsDone(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Green button
                  foregroundColor: Colors.white, // White text color
                ),
                child: _isMarkingAsDone
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)), // White indicator
                )
                    : const Text('Mark as Done'),
              ),
            if (acceptedByUserId == currentUser?.uid && status == 'completed')
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('You have completed this gig!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            if (postedByUserId == currentUser?.uid && status == 'completed')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RatingScreen(gig: widget.gig),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue button
                  foregroundColor: Colors.white, // White text color
                ),
                child: const Text('Rate this Gig'),
              ),
            if (acceptedByUserId != null && acceptedByUserId != currentUser?.uid && status != 'completed')
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('This gig has already been assigned to someone else.', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
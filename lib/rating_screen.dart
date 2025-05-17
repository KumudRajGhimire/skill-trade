import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> gig;

  const RatingScreen({super.key, required this.gig});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0.0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final gigPosterId = widget.gig['postedBy'];
      final gigAcceptedByUserId = widget.gig['acceptedByUserId'];

      if (gigAcceptedByUserId != null) {
        // Get the user document of the user who accepted the gig
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(gigAcceptedByUserId).get();

        if (userDoc.exists) {
          // Get the current rating and review count
          final currentRating = (userDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
          final currentReviewCount = (userDoc.data()?['reviewCount'] as num?)?.toInt() ?? 0;

          // Calculate the new rating and review count
          final newReviewCount = currentReviewCount + 1;
          final newRating = ((currentRating * currentReviewCount) + _rating) / newReviewCount;

          // Update the user document with the new rating and review count
          await FirebaseFirestore.instance.collection('users').doc(gigAcceptedByUserId).update({
            'rating': newRating,
            'reviewCount': newReviewCount,
          });

          // Send a notification to the user who accepted the gig
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': gigAcceptedByUserId,
            'type': 'rating_received',
            'gigId': widget.gig['id'],
            'gigTitle': widget.gig['title'],
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'rating': _rating,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rating submitted successfully!')),
          );

          // Navigate back to the GigDetailsScreen
          Navigator.pop(context);
        } else {
          // Show an error message if the user document does not exist
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find the user who accepted the gig.')),
          );
        }
      } else {
        // Show an error message if the gig has not been accepted by anyone
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This gig has not been accepted by anyone yet.')),
        );
      }
    } catch (e) {
      // Show an error message if there is an error submitting the rating
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating. Please try again.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text('Rate this Gig', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rate the job done for "${widget.gig['title']}"',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
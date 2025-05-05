import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gig.dart'; // Import your Gig model
import 'package:cloud_firestore/cloud_firestore.dart';

class PostGigScreen extends StatefulWidget {
  const PostGigScreen({super.key});

  @override
  _PostGigScreenState createState() => _PostGigScreenState();
}

class _PostGigScreenState extends State<PostGigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _offeringSkillController = TextEditingController();
  final TextEditingController _desiredSkillController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _postGig() async {
    if (_formKey.currentState!.validate()) {
      try {
        final User? user = _auth.currentUser;
        if (user != null) {
          // Fetch the current user's profile to get the username
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          final String? username = userDoc.data()?['username'] as String?;

          if (username != null) {
            final Gig newGig = Gig(
              offeringSkill: _offeringSkillController.text.trim(),
              desiredSkill: _desiredSkillController.text.trim(),
              description: _descriptionController.text.trim(),
              postedBy: user.uid,
              postedByUsername: username, // Store the poster's username
              postedDate: DateTime.now(),
              status: 'open',
            );

            // Add the new gig to the 'gigs' collection in Firestore
            await _firestore.collection('gigs').add(newGig.toFirestore());

            // Optionally, show a success message and navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gig posted successfully!')),
            );
            Navigator.pop(context); // Go back to the previous screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not retrieve your username.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to post a gig.')),
          );
        }
      } catch (e) {
        print('Error posting gig: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post gig. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Gig'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _offeringSkillController,
                decoration: const InputDecoration(
                  labelText: 'Offering Skill',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter the skill you are offering'
                    : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _desiredSkillController,
                decoration: const InputDecoration(
                  labelText: 'Desired Skill',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter the skill you are looking for'
                    : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter a description for the gig'
                    : null,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _postGig,
                child: const Text('Post Gig'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// post_gig_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostGigScreen extends StatefulWidget {
  final VoidCallback? onGigPosted;

  const PostGigScreen({super.key, this.onGigPosted});

  @override
  _PostGigScreenState createState() => _PostGigScreenState();
}

class _PostGigScreenState extends State<PostGigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _offeringSkillController = TextEditingController();
  final TextEditingController _desiredSkillController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController(); // For paid gigs
  String _gigType = 'Paid'; // Default to Paid
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _postGig() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          final username = userDoc.data()?['username'] as String?;

          if (username != null) {
            final newGig = {
              'title': _titleController.text.trim(),
              'offeringSkill': _offeringSkillController.text.trim(),
              'desiredSkill': _desiredSkillController.text.trim(),
              'description': _descriptionController.text.trim(),
              'location': _locationController.text.trim(),
              'gigType': _gigType,
              if (_gigType == 'Paid') 'payment': _paymentController.text.trim(),
              'postedBy': user.uid,
              'postedByUsername': username,
              'postedDate': DateTime.now(),
              'status': 'open',
            };

            await _firestore.collection('gigs').add(newGig);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gig posted successfully!')),
            );
            widget.onGigPosted?.call();
            Navigator.pop(context, true);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter a title for the gig'
                    : null,
              ),
              const SizedBox(height: 16.0),
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
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter the location for the gig'
                    : null,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gig Type',
                  border: OutlineInputBorder(),
                ),
                value: _gigType,
                items: <String>['Paid', 'Trade'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _gigType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              if (_gigType == 'Paid')
                TextFormField(
                  controller: _paymentController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_gigType == 'Paid' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter the payment amount';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
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
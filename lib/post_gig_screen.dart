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
              if (_gigType == 'Trade')
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
      backgroundColor: Colors.grey[900], // Dark background
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Darker app bar
        title: const Text('Post a Gig', style: TextStyle(color: Colors.white)), // White title
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
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
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue), // Blue focus border
                  ),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter a title for the gig'
                    : null,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Gig Type',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue), // Blue focus border
                  ),
                ),
                dropdownColor: Colors.grey[800], // Dark dropdown background
                style: const TextStyle(color: Colors.white), // White text
                value: _gigType,
                items: <String>['Paid', 'Trade'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)), // White text
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _gigType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              if (_gigType == 'Trade')
                TextFormField(
                  controller: _offeringSkillController,
                  style: const TextStyle(color: Colors.white), // White text
                  decoration: InputDecoration(
                    labelText: 'Offering Skill',
                    labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue), // Blue focus border
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter the skill you are offering'
                      : null,
                ),
              if (_gigType == 'Trade') const SizedBox(height: 16.0),
              TextFormField(
                controller: _desiredSkillController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Desired Skill',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue), // Blue focus border
                  ),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter the skill you are looking for'
                    : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white), // White text
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue), // Blue focus border
                  ),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter a description for the gig'
                    : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue), // Blue focus border
                  ),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Please enter the location for the gig'
                    : null,
              ),
              const SizedBox(height: 16.0),
              if (_gigType == 'Paid')
                TextFormField(
                  controller: _paymentController,
                  style: const TextStyle(color: Colors.white), // White text
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    labelStyle: TextStyle(color: Colors.grey[400]), // Lighter label
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!), // Darker border
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue), // Blue focus border
                    ),
                  ),
                  validator: (value) {
                    if (_gigType == 'Paid' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter the payment amount';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                ),
              if (_gigType == 'Paid') const SizedBox(height: 24.0),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _postGig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Darker button color
                  foregroundColor: Colors.white, // White text color
                ),
                child: const Text('Post Gig'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
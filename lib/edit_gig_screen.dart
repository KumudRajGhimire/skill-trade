import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditGigScreen extends StatefulWidget {
  final Map<String, dynamic> gigData;
  final String gigId;

  const EditGigScreen({super.key, required this.gigData, required this.gigId});

  @override
  State<EditGigScreen> createState() => _EditGigScreenState();
}

class _EditGigScreenState extends State<EditGigScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _offeringSkillController = TextEditingController();
  TextEditingController _desiredSkillController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _paymentController = TextEditingController();
  String? _gigType;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing gig data
    _titleController.text = widget.gigData['title'] ?? '';
    _descriptionController.text = widget.gigData['description'] ?? '';
    _offeringSkillController.text = widget.gigData['offeringSkill'] ?? '';
    _desiredSkillController.text = widget.gigData['desiredSkill'] ?? '';
    _locationController.text = widget.gigData['location'] ?? '';
    _paymentController.text = widget.gigData['payment']?.toString() ?? '';
    _gigType = widget.gigData['gigType'];
  }

  Future<void> _updateGig() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedGigData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'offeringSkill': _offeringSkillController.text.trim(),
          'desiredSkill': _desiredSkillController.text.trim(),
          'location': _locationController.text.trim(),
          'gigType': _gigType,
          if (_gigType != 'Trade' && _paymentController.text.isNotEmpty)
            'payment': double.tryParse(_paymentController.text.trim()),
          'postedDate': Timestamp.now(), // Update the posted date
        };

        await FirebaseFirestore.instance.collection('gigs').doc(widget.gigId).update(updatedGigData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gig updated successfully!')),
          );
          Navigator.pop(context); // Go back to the profile screen
        }
      } catch (e) {
        print('Error updating gig: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update gig. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _deleteGig(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[800], // Darker background for dialog
          title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)), // White text
          content: const Text('Are you sure you want to delete this gig? This action cannot be undone.', style: TextStyle(color: Colors.white70)), // Lighter text
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('gigs').doc(widget.gigId).delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gig deleted successfully!')),
                    );
                    Navigator.pop(dialogContext); // Dismiss the dialog
                    Navigator.pop(context); // Go back to the profile screen
                  }
                } catch (e) {
                  print('Error deleting gig: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete gig. Please try again.')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background color
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Darker app bar
        title: const Text('Edit Gig', style: TextStyle(color: Colors.white)), // White title
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Light grey label
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)), // Darker border
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Blue focus border
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Light grey label
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)), // Darker border
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Blue focus border
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _offeringSkillController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Offering Skill',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Light grey label
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)), // Darker border
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Blue focus border
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the skill you are offering';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desiredSkillController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Desired Skill',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Light grey label
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)), // Darker border
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Blue focus border
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the skill you are looking for';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white), // White text
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey[400]), // Light grey label
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)), // Darker border
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Blue focus border
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Trade', style: TextStyle(color: Colors.white)), // White text
                      value: 'Trade',
                      groupValue: _gigType,
                      onChanged: (value) {
                        setState(() {
                          _gigType = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Paid', style: TextStyle(color: Colors.white)), // White text
                      value: 'Paid',
                      groupValue: _gigType,
                      onChanged: (value) {
                        setState(() {
                          _gigType = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_gigType == 'Paid')
                TextFormField(
                  controller: _paymentController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white), // White text
                  decoration: InputDecoration(
                    labelText: 'Payment (₹)',
                    labelStyle: TextStyle(color: Colors.grey[400]), // Light grey label
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)), // Darker border
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Blue focus border
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_gigType == 'Paid' && (value == null || value.isEmpty)) {
                      return 'Please enter the payment amount';
                    }
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // To center and space buttons
                children: [
                  ElevatedButton(
                    onPressed: _updateGig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Blue button
                      foregroundColor: Colors.white, // White text
                    ),
                    child: const Text('Update Gig'),
                  ),
                  ElevatedButton(
                    onPressed: () => _deleteGig(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete Gig'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
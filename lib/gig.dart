import 'package:cloud_firestore/cloud_firestore.dart';

class Gig {
  final String? id;
  final String offeringSkill;
  final String desiredSkill;
  final String description;
  final String postedBy; // User ID of the poster
  final String? postedByUsername; // ADD THIS LINE
  final String? acceptedBy; // User ID of the acceptor (initially null)
  final DateTime? postedDate;
  String status; // e.g., 'open', 'pending', 'accepted', 'completed'

  Gig({
    this.id,
    required this.offeringSkill,
    required this.desiredSkill,
    required this.description,
    required this.postedBy,
    this.postedByUsername, // INCLUDE IN CONSTRUCTOR
    this.acceptedBy,
    this.postedDate,
    this.status = 'open',
  });

  // Factory method to create a Gig object from a Firestore document
  factory Gig.fromFirestore(Map<String, dynamic> data, String id) {
    return Gig(
      id: id,
      offeringSkill: data['offeringSkill'] ?? '',
      desiredSkill: data['desiredSkill'] ?? '',
      description: data['description'] ?? '',
      postedBy: data['postedBy'] ?? '',
      postedByUsername: data['postedByUsername'], // RETRIEVE FROM FIRESTORE
      acceptedBy: data['acceptedBy'],
      postedDate: (data['postedDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'open',
    );
  }

  // Method to convert a Gig object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'offeringSkill': offeringSkill,
      'desiredSkill': desiredSkill,
      'description': description,
      'postedBy': postedBy,
      'postedByUsername': postedByUsername, // SAVE TO FIRESTORE
      'acceptedBy': acceptedBy,
      'postedDate': postedDate ?? DateTime.now(),
      'status': status,
    };
  }
}
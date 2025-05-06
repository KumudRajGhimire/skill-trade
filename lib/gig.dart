// gig.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Gig {
  final String? id;
  final String? title;
  final String? offeringSkill;
  final String? desiredSkill;
  final String? description;
  final String? postedBy;
  final String? postedByUsername;
  final DateTime? postedDate;
  final String? status;
  final String? location; // Add location
  final String? deadline; // Add deadline

  Gig({
    this.id,
    this.title,
    this.offeringSkill,
    this.desiredSkill,
    this.description,
    this.postedBy,
    this.postedByUsername,
    this.postedDate,
    this.status,
    this.location,
    this.deadline,
  });

  // Factory method to create a Gig object from a Firestore document
  factory Gig.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Gig(
      id: snapshot.id,
      title: data?['title'],
      offeringSkill: data?['offeringSkill'],
      desiredSkill: data?['desiredSkill'],
      description: data?['description'],
      postedBy: data?['postedBy'],
      postedByUsername: data?['postedByUsername'],
      postedDate: (data?['postedDate'] as Timestamp?)?.toDate(),
      status: data?['status'],
      location: data?['location'],
      deadline: data?['deadline'],
    );
  }

  // Method to convert a Gig object to a Firestore compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'offeringSkill': offeringSkill,
      'desiredSkill': desiredSkill,
      'description': description,
      'postedBy': postedBy,
      'postedByUsername': postedByUsername,
      'postedDate': postedDate,
      'status': status,
      'location': location,
      'deadline': deadline,
    };
  }
}
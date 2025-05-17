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
  final String? location;
  final String? deadline;
  final String? gigType; // Added gig type
  final int? payment; // Added payment
  final String? acceptedByUserId; // Added accepted by user ID
  final DateTime? acceptedDate; // Added accepted date

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
    this.gigType,
    this.payment,
    this.acceptedByUserId,
    this.acceptedDate,
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
      gigType: data?['gigType'],
      payment: data?['payment'] as int?,
      acceptedByUserId: data?['acceptedByUserId'],
      acceptedDate: (data?['acceptedDate'] as Timestamp?)?.toDate(),
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
      'gigType': gigType,
      'payment': payment,
      'acceptedByUserId': acceptedByUserId,
      'acceptedDate': acceptedDate,
    };
  }
}
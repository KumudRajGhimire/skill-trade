// home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gig_details_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>> _fetchGigs() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('gigs')
          .where('postedBy', isNotEqualTo: currentUserId) // Filter out own posts
          .orderBy('postedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include the document ID in the data
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching gigs: $e');
      return [];
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {}); // Trigger a rebuild to call FutureBuilder again
  }

  void _navigateToGigDetails(Map<String, dynamic> gig) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GigDetailsScreen(gig: gig),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchGigs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading gigs: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final gigs = snapshot.data!;
              return ListView.builder(
                itemCount: gigs.length,
                itemBuilder: (context, index) {
                  final gig = gigs[index];
                  return GestureDetector(
                    onTap: () => _navigateToGigDetails(gig),
                    child: Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              gig['title'] as String? ?? 'No Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gig['description'] as String? ?? 'No Description',
                              style: const TextStyle(fontSize: 16),
                              maxLines: 2, // Keep description concise in the list
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    const Icon(Icons.location_on_outlined, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(gig['location'] as String? ?? 'No Location'),
                                  ],
                                ),
                                Text(
                                  gig['gigType'] == 'Trade'
                                      ? 'Trade'
                                      : gig['payment'] != null
                                      ? '₹${gig['payment']}'
                                      : 'Free',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Posted by: ${gig['postedByUsername'] as String? ?? 'Anonymous'}'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text('No gigs available at the moment. Pull down to refresh.'));
            }
          },
        ),
      ),
    );
  }
}
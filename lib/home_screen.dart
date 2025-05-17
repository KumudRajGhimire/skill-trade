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
  List<Map<String, dynamic>> _allGigs = [];
  List<Map<String, dynamic>> _filteredGigs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final String _defaultProfileImageUrl = 'assets/default_profile.png'; // Placeholder
  final List<Color> _cardColors = [
    const Color(0xffe4e4e4),
    const Color(0xFFB5B5B5)
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialGigs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialGigs() async {
    setState(() {
      _isLoading = true;
    });
    _allGigs = await _fetchGigsFromFirestore();
    _filteredGigs = List.from(_allGigs); // Initialize filtered list with all gigs
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchGigsFromFirestore() async {
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
    await _loadInitialGigs();
  }

  void _navigateToGigDetails(Map<String, dynamic> gig) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GigDetailsScreen(gig: gig),
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGigs = _allGigs.where((gig) {
        final title = (gig['title'] as String?)?.toLowerCase() ?? '';
        final description = (gig['description'] as String?)?.toLowerCase() ?? '';
        final location = (gig['location'] as String?)?.toLowerCase() ?? '';
        final gigType = (gig['gigType'] as String?)?.toLowerCase() ?? '';
        final postedByUsername = (gig['postedByUsername'] as String?)?.toLowerCase() ?? '';
        final desiredSkill = (gig['desiredSkill'] as String?)?.toLowerCase() ?? '';

        return title.contains(query) ||
            description.contains(query) ||
            location.contains(query) ||
            gigType.contains(query) ||
            postedByUsername.contains(query) ||
            desiredSkill.contains(query);
      }).toList();
    });
  }

  Future<void> _likeGig(String gigId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final gigRef = FirebaseFirestore.instance.collection('gigs').doc(gigId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(gigRef);
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      final likedBy = (data?['likedBy'] as List<dynamic>?)?.cast<String>() ?? [];

      if (!likedBy.contains(userId)) {
        transaction.update(gigRef, {'likedBy': [...likedBy, userId]});
      } else {
        transaction.update(gigRef, {'likedBy': likedBy.where((id) => id != userId).toList()});
      }
    });
    _loadInitialGigs(); // Refresh the gig list to update like counts
  }

  Future<void> _reportGig(String gigId) async {
    // In a real application, you would have more sophisticated reporting logic.
    // This is a basic implementation to meet the prompt's requirement.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gig reported')),
    );
    // You might want to store the report in a 'reports' collection in Firestore.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'H O M E',
          style: TextStyle(color: Colors.white), // Set the title text color to white
        ), // Added title here
        backgroundColor: Colors.black, // Set the background color to black
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search for gigs...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[850], // Set the background color to blackish grey
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredGigs.isEmpty
            ? LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: viewportConstraints.maxHeight,
                child: const Center(
                  child: Text('No gigs matching your search criteria.'),
                ),
              ),
            );
          },
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: _filteredGigs.length,
          itemBuilder: (context, index) {
            final gig = _filteredGigs[index];
            final likeCount = (gig['likedBy'] as List<dynamic>?)?.length ?? 0;
            final isLiked = (gig['likedBy'] as List<dynamic>?)?.contains(FirebaseAuth.instance.currentUser?.uid) ?? false;
            final cardColorIndex = index % _cardColors.length; // Cycle through colors

            return GestureDetector(
              onTap: () => _navigateToGigDetails(gig),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _cardColors[cardColorIndex], // Use the color from the list
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(_defaultProfileImageUrl),
                            radius: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gig['postedByUsername'] as String? ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SingleChildScrollView( // Make the offering row horizontally scrollable
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    gig['gigType'] == 'Trade'
                                        ? 'Offering: Trade'
                                        : gig['payment'] != null
                                        ? '₹${gig['payment']}'
                                        : 'Offering: Free',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ),
                                Text(
                                  'Req: ${gig['desiredSkill'] as String? ?? 'Desired Skill'}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.location_on_outlined, color: Colors.black54, size: 20),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gig['location'] as String? ?? 'No Location',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, color: Colors.black54),
                            offset: const Offset(-100, 20), // Adjust position of the popup
                            onSelected: (value) {
                              if (value == 'report') {
                                _reportGig(gig['id'] as String);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'report',
                                child: Text('Report'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        gig['description'] as String? ?? 'No Description',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _likeGig(gig['id'] as String),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.black54,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text('$likeCount', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _navigateToGigDetails(gig),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Read more',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
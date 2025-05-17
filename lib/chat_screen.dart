import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Import your ProfileScreen
import 'package:intl/intl.dart'; // For date and time formatting

class ChatScreen extends StatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? _otherUsername;

  @override
  void initState() {
    super.initState();
    _getOrCreateChatId();
    _loadOtherUsername();
    _markAsRead(); // Mark messages as read when entering the chat
  }

  Future<void> _markAsRead() async {
    if (_chatId != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .update({'unreadCount_$_currentUserId': 0});
    }
  }

  Future<void> _loadOtherUsername() async {
    try {
      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>?;
        _otherUsername = userData?['username'] as String? ?? 'User';
        if (mounted) setState(() {}); // Check if widget is still in the tree
      } else {
        _otherUsername = 'User'; // Default if user not found
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error loading other username: $e');
      _otherUsername = 'User'; // Default on error
      if (mounted) setState(() {});
    }
  }

  Future<void> _getOrCreateChatId() async {
    List<String> userIds = [_currentUserId, widget.otherUserId];
    userIds.sort();
    _chatId = userIds.join('_');

    DocumentSnapshot chatSnapshot =
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).get();

    if (!chatSnapshot.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'participants': [_currentUserId, widget.otherUserId],
        'createdAt': Timestamp.now(),
        'unreadCount_$_currentUserId': 0, // Initialize unread count for current user
        'unreadCount_${widget.otherUserId}': 0, // Initialize unread count for other user
      });
    } else {
      // Ensure unread count fields exist if the chat already exists
      final chatData = chatSnapshot.data() as Map<String, dynamic>?;
      if (chatData != null) {
        if (!chatData.containsKey('unreadCount_$_currentUserId')) {
          await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({'unreadCount_$_currentUserId': 0});
        }
        if (!chatData.containsKey('unreadCount_${widget.otherUserId}')) {
          await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({'unreadCount_${widget.otherUserId}': 0});
        }
      }
    }
    if (mounted) setState(() {}); // Trigger a rebuild once chatId is determined
  }

  void _sendMessage() async {
    if (_chatId != null && _messageController.text.trim().isNotEmpty) {
      final messageText = _messageController.text.trim();
      final timestamp = Timestamp.now();
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'text': messageText,
        'timestamp': timestamp,
      });
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'lastMessage': messageText,
        'lastMessageTimestamp': timestamp,
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1), // Increment recipient's unread count
      });
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _navigateToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.otherUserId), // Pass the other user's ID
      ),
    );
  }

  Widget _buildMessage(QueryDocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _currentUserId;
    final text = data['text'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate();
    final formattedTime = dateTime != null
        ? DateFormat('HH:mm').format(dateTime)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blueGrey[700] : Colors.grey[800], // Darker shades for black theme
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (formattedTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  formattedTime,
                  style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String formattedDate;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      formattedDate = 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      formattedDate = 'Yesterday';
    } else {
      formattedDate = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          formattedDate,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // Darker app bar color
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
        title: GestureDetector(
          onTap: _navigateToUserProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _otherUsername ?? 'Chat',
                style: const TextStyle(color: Colors.white), // White title text
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70), // Add the icon here
            ],
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white)) // White indicator
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Start chatting!', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final data = message.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateTime = timestamp?.toDate();

                    // Show date/time headers
                    if (index == 0) {
                      return Column(
                        children: [
                          if (dateTime != null) _buildDateHeader(dateTime),
                          _buildMessage(message),
                        ],
                      );
                    }

                    final previousMessage = snapshot.data!.docs[index - 1];
                    final previousData = previousMessage.data() as Map<String, dynamic>;
                    final previousTimestamp = previousData['timestamp'] as Timestamp?;
                    final previousDateTime = previousTimestamp?.toDate();

                    if (dateTime != null && previousDateTime != null &&
                        (dateTime.year != previousDateTime.year ||
                            dateTime.month != previousDateTime.month ||
                            dateTime.day != previousDateTime.day)) {
                      return Column(
                        children: [
                          _buildDateHeader(dateTime),
                          _buildMessage(message),
                        ],
                      );
                    }

                    return _buildMessage(message);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 25.0), // Increased bottom padding
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900], // Darker input field color
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(color: Colors.grey[700]!), // Darker border color
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white), // White text color
                      decoration: InputDecoration(
                        hintText: 'Type here...',
                        hintStyle: TextStyle(color: Colors.grey[500]), // Lighter hint text
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: Colors.blueGrey[700], // Darker send button color
                  radius: 25.0,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
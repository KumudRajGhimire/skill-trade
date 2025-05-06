// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Import your ProfileScreen

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _navigateToUserProfile,
          child: Text(_otherUsername ?? 'Chat'),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Start chatting!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final data = message.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    final text = data['text'] as String? ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateTime = timestamp?.toDate();
                    final formattedTime = dateTime != null
                        ? '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'
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
                                color: isMe ? Colors.blue[300] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                              ),
                            ),
                            if (formattedTime.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  formattedTime,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
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
import 'dart:io';

import 'package:capstone_project/models/lost_item_model.dart';
import 'package:capstone_project/models/message_model.dart';
import 'package:capstone_project/models/user_provider.dart';
import 'package:capstone_project/pages/chat/preview_page.dart';
import 'package:capstone_project/pages/finish_transaction.dart';
import 'package:capstone_project/services/remote_service.dart';
import 'package:capstone_project/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:capstone_project/themes/theme.dart';
import 'package:capstone_project/components/chat_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ConversationPage extends StatefulWidget {
  final String chatId;
  final String memberId;
  final String memberName;
  final String memberImage;
  final String itemId;
  final String itemName;
  final String itemDate;
  ConversationPage({
    super.key,
    required this.chatId,
    required this.memberId,
    required this.memberName,
    required this.memberImage,
    required this.itemId,
    required this.itemName,
    required this.itemDate,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late FocusNode _focusNode;
  late TextEditingController _textEditingController;
  bool _isFocused = false;
  List<Message> _messages = []; // Store fetched messages here
  late String itemStatus = '';
  bool foundUserStatus = false; // Variable to store foundUserStatus
  bool lostUserStatus = false; // Variable to store lostUserStatus

  final SocketService _socketService = SocketService(); // Use SocketService instance

  final RemoteService _remoteService =
      RemoteService(); // Create an instance of RemoteService

  _connectSocket() {
    _socketService.socket?.onConnect((data) => print('Connected'));
    _socketService.socket
        ?.onConnectError((data) => print('Connect Error: $data'));
    _socketService.socket?.onDisconnect((data) => print('Disconnected'));
  }

  // Method to initialize the socket
  Future<void> initializeSocket() async {
    try {
      await _socketService
          .initializeSocket(); // Initialize socket using SocketService
      // print('Socket connected');
      // Register reconnect logic
      _socketService.socket?.onDisconnect((_) {
        // print('Socket disconnected, reconnecting...');
        initializeSocket(); // Reconnect
      });
      final uid = Provider.of<UserProvider>(context, listen: false).uid;
      _socketService.socket?.emit("new-user-add", uid);
      _socketService.socket?.on("receive-message", (data) {
        if (data is Map<String, dynamic>) {
          String receiverId = data['receiverId'];
          if (receiverId != widget.memberId) {
            String? messageText = data['message'];
            String? imageUrl = data['imageUrl'];
            if (imageUrl != null) {
              // If imageUrl is present
              String senderId = data['senderId'];
              DateTime createdAt = DateTime.now();
              Message receivedMessage = Message(
                senderId: senderId,
                message: null,
                imageUrl: imageUrl,
                createdAt: createdAt,
              );
              // Check if the widget is mounted before calling setState
              if (mounted) {
                setState(() {
                  _messages.add(receivedMessage);
                });
              }
            } else if (messageText != null) {
              // If messageText is present
              String senderId = data['senderId'];
              DateTime createdAt = DateTime.now();
              Message receivedMessage = Message(
                senderId: senderId,
                message: messageText,
                imageUrl: null,
                createdAt: createdAt,
              );
              // Check if the widget is mounted before calling setState
              if (mounted) {
                setState(() {
                  _messages.add(receivedMessage);
                });
              }
            }
          }
        }
      });
    } catch (e) {
    }
  }

  void _sendMessageToRemote(String message, String chatId, String token) async {
    try {
      String senderId =
          Provider.of<UserProvider>(context, listen: false).uid ?? '';
      await _remoteService.sendMessage(
          chatId: chatId, token: token, message: message);
      // Emit message to the socket server
      _socketService.socket?.emit("send-message", {
        'senderId': senderId,
        'receiverId': widget.memberId,
        'message': message
      });
      // Confirmation message
      // Add the sent message to the UI directly
      Message sentMessage = Message(
        senderId: senderId,
        message: message,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(sentMessage);
      });
      // Clear the text field after sending the message
      _textEditingController.clear();
    } catch (e) {
      // Handle error appropriately
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

// Method to fetch messages
  void _fetchMessages() async {
    try {
      List<Message> messages = await RemoteService().getMessages(widget.chatId);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
    }
  }

  Future<void> getItemDetails(String itemId) async {
  try {
    if (itemId.startsWith('fou')) {
      dynamic foundItem = await _remoteService.getFoundByIdJson(itemId);
      if (foundItem != null) {
        foundUserStatus = foundItem['foundUserStatus']; // Update class-level variable
        lostUserStatus = foundItem['lostUserStatus']; // Update class-level variable
        if (!foundUserStatus && !lostUserStatus) {
          itemStatus = 'Available';
        } else if (!lostUserStatus && foundUserStatus) {
          itemStatus = 'Awaiting founder approval';
        } else if (!foundUserStatus && lostUserStatus) {
          itemStatus = 'Awaiting lost user approval';
        } else {
          itemStatus = 'Item Claimed';
        }
      } else {
      }
    } else if (itemId.startsWith('los')) {
      Datum? lostItem = await _remoteService.getLostItemById(itemId);
      if (lostItem != null) {
        foundUserStatus = lostItem.foundUserStatus; // Update class-level variable
        lostUserStatus = lostItem.lostUserStatus; // Update class-level variable
        if (!foundUserStatus && !lostUserStatus) {
          itemStatus = 'Available';
        } else if (!lostUserStatus && foundUserStatus) {
          itemStatus = 'Awaiting founder approval';
        } else if (!foundUserStatus && lostUserStatus) {
          itemStatus = 'Awaiting lost user approval';
        } else {
          itemStatus = 'Item Claimed';
        }
      } else {
      }
    } else {
    }
    // Update the UI after fetching item details
    setState(() {});
  } catch (e) {
  }
}


  // Method to navigate to ImagePreviewPage and handle the result
  Future<void> _navigateToImagePreviewPage(File imageFile) async {
    final sentMessage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewPage(
          imageFile: imageFile,
          chatId: widget.chatId,
          memberId: widget.memberId,
        ),
      ),
    );
    if (sentMessage != null) {
      setState(() {
        _messages.add(sentMessage);
      });
    }
  }

// Function to handle selecting an image from the device's gallery
  Future<void> _getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _navigateToImagePreviewPage(File(pickedFile.path));
    } else {
      // User canceled the picker
    }
  }

  @override
  void initState() {
    super.initState();
    initializeSocket();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _textEditingController = TextEditingController();
    _fetchMessages();
    getItemDetails(widget.itemId);
    itemStatus = 'Loading...';
  }

  // Widget to build chat bubbles from messages
  Widget _buildChatBubbles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _messages.map((message) {
        // Check if the message is null and imageUrl is present
        if (message.message == null && message.imageUrl != null) {
          bool isUserMessage = message.senderId != widget.memberId;
          return isUserMessage
              ? ChatBubbleUser(
                  imageUrl: message.imageUrl!,
                )
              : ChatBubble(
                  imageUrl: message.imageUrl!,
                );
        }
        // Check if the message is present and imageUrl is either present or not
        else if (message.message != null) {
          bool isUserMessage = message.senderId != widget.memberId;
          return isUserMessage
              ? ChatBubbleUser(
                  text: message.message!,
                )
              : ChatBubble(
                  text: message.message!,
                );
        } else {
          return Container(); // Return an empty container for other cases
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Change body color to white
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Row(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.memberImage),
                  radius: 16, // Adjust the size as needed
                ),
                const SizedBox(width: 8), // Adjust the spacing between image and text
                Container(
                  // Wrap the Text widget with Container
                  constraints: const BoxConstraints(
                      maxWidth: 90), // Adjust the maximum width as needed
                  child: Text(
                    widget.memberName,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, // Handle long names
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FinishTransaction(
                            itemId: widget.itemId,
                            itemName: widget.itemName,
                            itemDate: widget.itemDate,
                            foundUserStatus:
                                foundUserStatus, // Pass foundUserStatus
                            lostUserStatus:
                                lostUserStatus, // Pass lostUserStatus
                          )), // Replace FinishPage with the actual page you want to navigate to
                );
                // getItemDetails(widget.itemId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'FINISH TRANSACTION',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [],
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction of: ${widget.itemName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white),
                ),
                Text(
                  itemStatus,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.yellow),
                )
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildChatBubbles(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: TextField(
                        controller: _textEditingController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16.0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (!_isFocused) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final chatId = widget.chatId;
                        final token =
                            Provider.of<UserProvider>(context, listen: false)
                                .token;
                        final message = _textEditingController.text;
                        ''; // Empty string for now, replace with actual imageUrl when sending an image
                        if (token != null) {
                          _sendMessageToRemote(message, chatId,
                              token); // Pass imageUrl to the function
                          _textEditingController
                              .clear(); // Clear the text field after sending the message
                        } else {
                          // Handle the case where one of the parameters is null
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Action to send image
                        _getImageFromGallery();
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final chatId = widget.chatId;
                        final token =
                            Provider.of<UserProvider>(context, listen: false)
                                .token;
                        final message = _textEditingController.text;

                        ''; // Empty string for now, replace with actual imageUrl when sending an image
                        if (token != null) {
                          _sendMessageToRemote(message, chatId,
                              token); // Pass imageUrl to the function
                          _textEditingController
                              .clear(); // Clear the text field after sending the message
                        } else {
                          // Handle the case where one of the parameters is null
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

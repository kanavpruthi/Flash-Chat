import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseUser loggedInUser;
final _firestore = Firestore.instance;

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();

  final _auth = FirebaseAuth.instance;

  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
      print(loggedInUser.email);
    } catch (err) {
      print(err);
    }
  }

//  void getMessages() async {
//    var messages = await _firestore.collection('messages').getDocuments();
//    for (var message in messages.documents) {
//      print(message.data);
//    }
//  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.documents) {
        print(message.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(color: Colors.black, fontSize: 20),
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration.copyWith(
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'sender': loggedInUser.email,
                        'text': messageText,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String messageText;
  final String messageSender;
  final bool isMe;
  MessageBubble(
      {@required this.messageSender,
      @required this.messageText,
      @required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messageSender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Material(
            elevation: 5.0,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '$messageText',
                style: TextStyle(
                  fontSize: 20,
                  color: isMe ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ),
            color: isMe ? Colors.lightBlueAccent : Colors.grey,
          ),
        ],
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        List<Widget> messageWidgets = [];
        if (snapshot.hasData) {
          final messages = snapshot.data.documents.reversed;
          for (var message in messages) {
            final messageSender = message.data['sender'];
            final messageText = message.data['text'];

            final currentUser = loggedInUser.email;
            if (currentUser == messageSender) {}

            final widget = MessageBubble(
              messageSender: messageSender,
              messageText: messageText,
              isMe: currentUser == messageSender,
            );
            messageWidgets.add(widget);
          }
        } else {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

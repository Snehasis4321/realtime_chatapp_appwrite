import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/models/chat_data_model.dart';
import 'package:realtime_chatapp_appwrite/models/message_model.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';

class ChatProvider extends ChangeNotifier {
  Map<String, List<ChatDataModel>> _chats = {};

  // get all users chats
  Map<String, List<ChatDataModel>> get getAllChats => _chats;

  Timer? _debounce;

  // to load all current user chats
  void loadChats(String currentUser) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(seconds: 1), () async {
      Map<String, List<ChatDataModel>>? loadedChats =
          await currentUserChats(currentUser);

      if (loadedChats != null) {
        _chats = loadedChats;

        _chats.forEach((key, value) {
          // sorting in descending timestamp
          value.sort(
              (a, b) => a.message.timestamp.compareTo(b.message.timestamp));
        });
        print("chats updated in provider");

        notifyListeners();
      }
    });
  }

  // add the chat message when user send a new message to someone else
  void addMessage(
      MessageModel message, String currentUser, List<UserData> users) {
    try {
      if (message.sender == currentUser) {
        if (_chats[message.receiver] == null) {
          _chats[message.receiver] = [];
        }

        _chats[message.receiver]!
            .add(ChatDataModel(message: message, users: users));
      } else {
        //  the current user is receiver
        if (_chats[message.sender] == null) {
          _chats[message.sender] = [];
        }

        _chats[message.sender]!
            .add(ChatDataModel(message: message, users: users));
      }

      notifyListeners();
    } catch (e) {
      print("error in chatprovider on message adding");
    }
  }

  // delete message from the chats data
  void deleteMessage(MessageModel message, String currentUser) async {
    try {
      // user is delete the message
      if (message.sender == currentUser) {
        _chats[message.receiver]!
            .removeWhere((element) => element.message == message);

        if (message.isImage == true) {
          deleteImagefromBucket(oldImageId: message.message);
          print("image deleted from bucket");
        }

        deleteCurrentUserChat(chatId: message.messageId!);
      } else {
        // current user is receiver
        _chats[message.sender]!
            .removeWhere((element) => element.message == message);
            deleteCurrentUserChat(chatId: message.messageId!);
        print("message deleted");
      }
      notifyListeners();
    } catch (e) {
      print("error on message deletion");
    }
  }

  // clear all chats
  void clearChats() {
    _chats = {};
    notifyListeners();
  }
}

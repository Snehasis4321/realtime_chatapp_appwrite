import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/constants/formate_date.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/controllers/fcm_controllers.dart';
import 'package:realtime_chatapp_appwrite/models/chat_data_model.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';
import 'package:realtime_chatapp_appwrite/providers/chat_provider.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String currentUserid = "";

  @override
  void initState() {
    currentUserid =
        Provider.of<UserDataProvider>(context, listen: false).getUserId;
    Provider.of<ChatProvider>(context, listen: false).loadChats(currentUserid);
    PushNotifications.getDeviceToken();
    subscribeToRealtime(userId: currentUserid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    updateOnlineStatus(status: true, userId: currentUserid);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: kBackgroundColor,
        title: Text(
          "Chats",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/profile"),
              child:
                  Consumer<UserDataProvider>(builder: (context, value, child) {
                return CircleAvatar(
                  backgroundImage: value.getUserProfile != null ||
                          value.getUserProfile != ""
                      ? CachedNetworkImageProvider(
                          "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${value.getUserProfile}/view?project=662e8e5c002f2d77a17c&mode=admin")
                      : Image(
                          image: AssetImage("assets/user.png"),
                        ).image,
                );
              }))
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, value, child) {
          if (value.getAllChats.isEmpty) {
            return Center(
              child: Text("No Chats"),
            );
          } else {
            List otherUsers = value.getAllChats.keys.toList();
            return ListView.builder(
                itemCount: otherUsers.length,
                itemBuilder: (context, index) {
                  List<ChatDataModel> chatData =
                      value.getAllChats[otherUsers[index]]!;

                  int totalChats = chatData.length;

                  UserData otherUser =
                      chatData[0].users[0].userId == currentUserid
                          ? chatData[0].users[1]
                          : chatData[0].users[0];

                  int unreadMsg = 0;

                  chatData.fold(
                    unreadMsg,
                    (previousValue, element) {
                      if (element.message.isSeenByReceiver == false) {
                        unreadMsg++;
                      }
                      return unreadMsg;
                    },
                  );
                  return ListTile(
                    onTap: () => Navigator.pushNamed(context, "/chat",
                        arguments: otherUser),
                    leading: Stack(children: [
                      CircleAvatar(
                        backgroundImage: otherUser.profilePic == "" ||
                                otherUser.profilePic == null
                            ? Image(
                                image: AssetImage("assets/user.png"),
                              ).image
                            : CachedNetworkImageProvider(
                                "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${otherUser.profilePic}/view?project=662e8e5c002f2d77a17c&mode=admin"),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 6,
                          backgroundColor: otherUser.isOnline == true
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      )
                    ]),
                    title: Text(otherUser.name!),
                    subtitle: Text(
                      "${chatData[totalChats - 1].message.sender == currentUserid ? "You : " : ""}${chatData[totalChats - 1].message.isImage == true ? "Sent an image" : chatData[totalChats - 1].message.message}",
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        chatData[totalChats - 1].message.sender != currentUserid
                            ? unreadMsg != 0
                                ? CircleAvatar(
                                    backgroundColor: kPrimaryColor,
                                    radius: 10,
                                    child: Text(
                                      unreadMsg.toString(),
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.white),
                                    ),
                                  )
                                : SizedBox()
                            : SizedBox(),
                        SizedBox(
                          height: 8,
                        ),
                        Text(formatDate(
                            chatData[totalChats - 1].message.timestamp))
                      ],
                    ),
                  );
                });
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/search");
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

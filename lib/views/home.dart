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
import 'package:realtime_chatapp_appwrite/models/group_message_model.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';
import 'package:realtime_chatapp_appwrite/providers/chat_provider.dart';
import 'package:realtime_chatapp_appwrite/providers/group_message_provider.dart';
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
    Provider.of<GroupMessageProvider>(context, listen: false)
        .loadAllGroupRequiredData(currentUserid);
    PushNotifications.getDeviceToken();
    subscribeToRealtime(userId: currentUserid);
    subscribeToRealtimeGroupMsg(userId: currentUserid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    updateOnlineStatus(status: true, userId: currentUserid);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          backgroundColor: kBackgroundColor,
          title: Text(
            "Fast Chat",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            GestureDetector(
                onTap: () => Navigator.pushNamed(context, "/profile"),
                child: Consumer<UserDataProvider>(
                    builder: (context, value, child) {
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
          bottom: TabBar(tabs: [
            Tab(
              text: "Direct Messages",
            ),
            Tab(
              text: "Group Messages",
            )
          ]),
        ),
        body: TabBarView(children: [
          Consumer<ChatProvider>(
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

                      if (chatData.isEmpty) {
                        return SizedBox.shrink();
                      }

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
                          chatData[totalChats - 1].message.isGroupInvite
                              ? "${chatData[totalChats - 1].message.sender == currentUserid ? "You sent a group invite " : "Receive a group invite"}"
                              : "${chatData[totalChats - 1].message.sender == currentUserid ? "You : " : ""}${chatData[totalChats - 1].message.isImage == true ? "Sent an image" : chatData[totalChats - 1].message.message}",
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            chatData[totalChats - 1].message.sender !=
                                    currentUserid
                                ? unreadMsg != 0
                                    ? CircleAvatar(
                                        backgroundColor: kPrimaryColor,
                                        radius: 10,
                                        child: Text(
                                          unreadMsg.toString(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
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
          Consumer<GroupMessageProvider>(
            builder: (context, value, child) {
              if (value.getJoinedGroups.isEmpty) {
                return Center(child: Text("No Group Joined"));
              } else {
                 // Sort groups based on the timestamp of the latest message in each group
    value.getJoinedGroups.sort((a, b) {
      String groupIdA = a.groupId;
      String groupIdB = b.groupId;

      // Get the latest message for group A
      List<GroupMessageModel>? messagesA = value.getGroupMessages?[groupIdA];
      DateTime? latestTimestampA = messagesA != null && messagesA.isNotEmpty
          ? messagesA.last.timestamp
          : DateTime.fromMillisecondsSinceEpoch(0); // Default old date if no messages

      // Get the latest message for group B
      List<GroupMessageModel>? messagesB = value.getGroupMessages?[groupIdB];
      DateTime? latestTimestampB = messagesB != null && messagesB.isNotEmpty
          ? messagesB.last.timestamp
          : DateTime.fromMillisecondsSinceEpoch(0); // Default old date if no messages

      // Sort in descending order by timestamp
      return latestTimestampB.compareTo(latestTimestampA);
    });
                return Column(
                  children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ListTile(
                                          onTap: () => Navigator.pushNamed(context,"/explore_groups"),
                                          leading: Icon(Icons.groups_outlined),
                                          title: Text("Explore Groups"),
                                          trailing: Icon(
                                            Icons
                          .arrow_forward_ios, // Add an arrow for navigation indication
                                            color: Colors.grey, // Subtle arrow color
                                            size: 18,
                                          ),
                                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: value.getJoinedGroups.length,
                        itemBuilder: (context, index) {
                          String groupId = value.getJoinedGroups[index].groupId;
                          // get the latest message
                          List<GroupMessageModel>? messages =
                              value.getGroupMessages[groupId];
                              
                          GroupMessageModel? latestMessage =
                              messages != null && messages.isNotEmpty
                                  ? messages.last
                                  : null;
                      
                          return ListTile(
                            onTap: () => Navigator.pushNamed(
                                context, "/read_group_message",
                                arguments: value.getJoinedGroups[index]),
                            leading: CircleAvatar(
                              backgroundImage: value.getJoinedGroups[index].image ==
                                          "" ||
                                      value.getJoinedGroups[index].image == null
                                  ? Image(
                                      image: AssetImage("assets/user.png"),
                                    ).image
                                  : CachedNetworkImageProvider(
                                      "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${value.getJoinedGroups[index].image}/view?project=662e8e5c002f2d77a17c&mode=admin"),
                            ),
                            title: Text(value.getJoinedGroups[index].groupName),
                            subtitle: Text(
                              latestMessage==null? "No Message":
                              "${latestMessage!.senderId == currentUserid ? "You : " : "${latestMessage.userData[0].name ?? "No Name"} : "}${latestMessage.isImage == true ? "Sent an image" : latestMessage.message}",
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FutureBuilder(
                                  future: calculateUnreadMessages(
                                      groupId, messages ?? []),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return SizedBox();
                                    } else if (snapshot.hasError) {
                                      return SizedBox();
                                    } else {
                                      int unreadMsgCount = snapshot.data ?? 0;
                                      return unreadMsgCount == 0
                                          ? SizedBox()
                                          : CircleAvatar(
                                              backgroundColor: kPrimaryColor,
                                              radius: 10,
                                              child: Text(
                                                "$unreadMsgCount",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white),
                                              ),
                                            );
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                latestMessage==null?SizedBox():
                                Text(formatDate(latestMessage.timestamp))
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          )
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, "/search");
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

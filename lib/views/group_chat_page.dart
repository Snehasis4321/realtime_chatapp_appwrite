import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/constants/group_chat_message.dart';
import 'package:realtime_chatapp_appwrite/constants/memberCalculate.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/models/group_message_model.dart';
import 'package:realtime_chatapp_appwrite/models/group_model.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';
import 'package:realtime_chatapp_appwrite/providers/group_message_provider.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  TextEditingController _messageController = TextEditingController();
  TextEditingController _editMessageController = TextEditingController();
  late String currentUser = "";
  late String currentUserName = "";

  FilePickerResult? _filePickerResult;

  @override
  void initState() {
    currentUser =
        Provider.of<UserDataProvider>(context, listen: false).getUserId;
    currentUserName =
        Provider.of<UserDataProvider>(context, listen: false).getUserName;
    super.initState();
  }

  // to open file picker
  void _openFilePicker(GroupModel groupData) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);

    setState(() {
      _filePickerResult = result;
      uploadAllImage(groupData);
    });
  }

  // to upload files to our storage bucket and our database
  void uploadAllImage(GroupModel groupData) async {
    if (_filePickerResult != null) {
      _filePickerResult!.paths.forEach((path) {
        if (path != null) {
          var file = File(path);
          final fileBytes = file.readAsBytesSync();
          final inputfile = InputFile.fromBytes(
              bytes: fileBytes, filename: file.path.split("/").last);

          // saving image to our storage bucket
          saveImageToBucket(image: inputfile).then((imageId) {
            if (imageId != null) {
              sendGroupMessage(
                  groupId: groupData.groupId,
                  message: imageId,
                  senderId: currentUser,
                  isImage: true);
              List<String> userTokens=[];

              for(var i=0;i<groupData.userData.length;i++){
                if(groupData.userData[i].userId!=currentUser){
                userTokens.add(groupData.userData[i].deviceToken??"");
                }
              }
              print("users token are $userTokens");
               sendMultipleNotificationtoOtherUser(notificationTitle: "Received an image in ${groupData.groupName}", notificationBody: '${currentUserName}: Sent and image', deviceToken:userTokens );
                  
            }
          });
        }
      });
    } else {
      print("file pick cancelled by user");
    }
  }

  void _sendGroupMessage(
      {required String groupId,
      required GroupModel groupData,
      required String message,
      required String senderId,
      bool? isImage}) async {
    await sendGroupMessage(
            groupId: groupId,
            message: message,
            isImage: isImage,
            senderId: senderId)
        .then((value) {
      if (value) {
         List<String> userTokens=[];

              for(var i=0;i<groupData.userData.length;i++){
                if(groupData.userData[i].userId!=currentUser){
                userTokens.add(groupData.userData[i].deviceToken??"");
                }
              }
              print("users token are $userTokens");
              sendMultipleNotificationtoOtherUser(notificationTitle: "Received a message in ${groupData.groupName}", notificationBody: '${currentUserName}: ${_messageController.text}', deviceToken:userTokens );
        Provider.of<GroupMessageProvider>(context, listen: false)
            .addGroupMessage(
                groupId: groupId,
                msg: GroupMessageModel(
                    messageId: "",
                    groupId: groupId,
                    message: message,
                    senderId: senderId,
                    timestamp: DateTime.now(),
                    userData: [UserData(phone: "", userId: senderId)],
                    isImage: isImage));
      }
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GroupModel groupData =
        ModalRoute.of(context)!.settings.arguments as GroupModel;
            Provider.of<GroupMessageProvider>(context,listen: false).loadAllGroupData(Provider.of<UserDataProvider>(context,listen: false).getUserId);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        leadingWidth: 40,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(context, "/group_detail",
              arguments: groupData),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: groupData.image == "" ||
                        groupData.image == null
                    ? Image(
                        image: AssetImage("assets/user.png"),
                      ).image
                    : CachedNetworkImageProvider(
                        "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${groupData.image}/view?project=662e8e5c002f2d77a17c&mode=admin"),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupData.groupName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    memCal(groupData.members.length),
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              if (groupData.isPublic || groupData.admin == currentUser)
                PopupMenuItem<String>(
                    onTap: () => Navigator.pushNamed(context, "/invite_members",
                        arguments: groupData),
                    child: Row(
                      children: [
                        Icon(Icons.group_add_outlined),
                        SizedBox(
                          width: 8,
                        ),
                        Text("Invite Members")
                      ],
                    )),
              if (groupData.admin == currentUser)
                PopupMenuItem<String>(
                    onTap: () => Navigator.pushNamed(context, "/modify_group",
                            arguments: groupData),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(
                          width: 8,
                        ),
                        Text("Edit Group")
                      ],
                    )),
              if (groupData.admin != currentUser)
                PopupMenuItem<String>(
                    onTap: () async {
                      await exitGroup(
                              groupId: groupData.groupId,
                              currentUser: currentUser)
                          .then((value) {
                        if (value) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Group Left Successfully.")));
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to exit group.")));
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app),
                        SizedBox(
                          width: 8,
                        ),
                        Text("Exit Group")
                      ],
                    )),
            ],
            child: Icon(Icons.more_vert),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Consumer<GroupMessageProvider>(
            builder: (context, value, child) {
              Map<String, List<GroupMessageModel>> allGroupMessages =
                  value.getGroupMessages;
              List<GroupMessageModel> thisGroupMsg =
                  allGroupMessages[groupData.groupId] ?? [];
              // reverse the list
              List<GroupMessageModel> reversedMsg =
                  thisGroupMsg.reversed.toList();
                  if(thisGroupMsg.length>0){
  updateLastMessageSeen(groupData.groupId, thisGroupMsg.last.messageId);
                  }
      Provider.of<GroupMessageProvider>(context,listen: false).loadAllGroupData(Provider.of<UserDataProvider>(context,listen: false).getUserId);
              return ListView.builder(
                reverse: true,
                itemCount: reversedMsg.length,
                itemBuilder: (context, index) => GestureDetector(
                    onLongPress: () {
                      final msg=reversedMsg[index];
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: msg.isImage == true
                                    ? Text(msg.senderId==currentUser || groupData.admin==currentUser
                                        ? "Chosse what you want to do with this image."
                                        : "This image cant be modified")
                                    : Text(
                                        "${msg.message.length > 20 ? msg.message.substring(0, 20) : msg.message} ..."),
                                content: msg.isImage == true
                                    ? Text(msg.senderId==currentUser || groupData.admin==currentUser
                                        ? 'Delete this image'
                                        : 'This image cant be deleted')
                                    : Text(msg.senderId==currentUser || groupData.admin==currentUser
                                        ? 'Chosse what you want to do with this message.'
                                        : 'This message cant be modified'),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text("Cancel")),
                                  (msg.senderId==currentUser || groupData.admin==currentUser) &&(msg.isImage==false)
                                      ? TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _editMessageController.text =
                                                msg.message;

                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                      title: Text(
                                                          "Edit this message"),
                                                      content: TextFormField(
                                                        controller:
                                                            _editMessageController,
                                                        maxLines: 10,
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () {
                                                           updateGroupMessage(messageId: msg.messageId,
                                                            newMessage: _editMessageController.text).
                                                            then((value)=> Navigator.pop(context));
                                                            
                                                            },
                                                            child: Text("Ok")),
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child:
                                                                Text("Cancel")),
                                                      ],
                                                    ));
                                          },
                                          child: Text("Edit"))
                                      : SizedBox(),
                                  msg.senderId==currentUser || groupData.admin==currentUser
                                      ? TextButton(
                                          onPressed: () {
                                        deleteGroupMessage(messageId:  msg.messageId);

                                            Navigator.pop(context);
                                          },
                                          child: Text("Delete"))
                                      : SizedBox(),
                                ],
                              ),
                            );
                          },
                    child: GroupChatMessage(
                        msg: reversedMsg[index],
                        currentUser: currentUser,
                        isImage: reversedMsg[index].isImage ?? false)),
              );
            },
          )),
          Container(
            margin: EdgeInsets.all(6),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  onSubmitted: (value) {
                    _sendGroupMessage(
                      groupData: groupData,
                        groupId: groupData.groupId,
                        message: _messageController.text,
                        senderId: currentUser);
                  },
                  controller: _messageController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: "Type a message ..."),
                )),
                IconButton(
                    onPressed: () {
                      _openFilePicker(groupData);
                    },
                    icon: Icon(Icons.image)),
                IconButton(
                    onPressed: () {
                      _sendGroupMessage(
                        groupData: groupData,
                          groupId: groupData.groupId,
                          message: _messageController.text,
                          senderId: currentUser);
                    },
                    icon: Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

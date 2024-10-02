import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/constants/formate_date.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/models/message_model.dart';
import 'package:realtime_chatapp_appwrite/providers/chat_provider.dart';

class ChatMessage extends StatefulWidget {
  final MessageModel msg;
  final String currentUser;
  final bool isImage;
  const ChatMessage(
      {super.key,
      required this.msg,
      required this.currentUser,
      required this.isImage});

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  @override
  Widget build(BuildContext context) {
     Map groupInviteData= widget.msg.isGroupInvite==true?jsonDecode(widget.msg.message)??{}:{};
    return
    widget.msg.isGroupInvite==true?
    Container(
      padding: EdgeInsets.all(8),
      child: Column(
         mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.msg.sender == widget.currentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
      
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(widget.msg.sender == widget.currentUser
                          ? "You send a group invitation for ${groupInviteData["name"]}."
                          : "Group invitation for ${groupInviteData["name"]}."),
                      ),
                        Container(
                          width: MediaQuery.of(context).size.width*.8,
                                decoration: BoxDecoration(
                        color: widget.msg.sender == widget.currentUser
                            ? Colors.blue.shade400
                            : kSecondaryColor,
                        borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(children: [
                           CircleAvatar(radius:  35, backgroundImage: 
                            groupInviteData["image"]==null&&groupInviteData["image"]==""?
                            Image(
                                    image: AssetImage("assets/user.png"),
                                  ).image:
                                  CachedNetworkImageProvider(
                                    "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${groupInviteData["image"]}/view?project=662e8e5c002f2d77a17c&mode=admin"
                                  )
                           ),
                            Text(groupInviteData["name"] ?? "",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: widget.msg.sender == widget.currentUser
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500),),
                            Text(groupInviteData["desc"] ?? "",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: widget.msg.sender == widget.currentUser
                                    ? Colors.white
                                    : Colors.black,
                                                ),),
                                                SizedBox(height: 10,),
                                                Row(
                          mainAxisAlignment:  MainAxisAlignment.center,children: [
                          ElevatedButton(onPressed: ()async{
                            if(widget.msg.sender == widget.currentUser){
                              // cancel the invitation
                              Provider.of<ChatProvider>(context,
                                                    listen: false)
                                                .deleteMessage(
                                                    widget.msg, widget.currentUser);

                                        
                            }
                            else{
                              await addUserToGroup(groupId: groupInviteData["id"], currentUser: widget.currentUser).then((value)
                              {
                                if(value){
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined ${groupInviteData["name"]} group successfully.")));
                                     Provider.of<ChatProvider>(context,
                                                    listen: false)
                                                .deleteMessage(
                                                    widget.msg, widget.currentUser);
                                }
                                else{
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error in joining group.")));
                                }
                              });
                                    
                              
                            }
                          }, 
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                        widget.msg.sender == widget.currentUser
                                            ? Colors.white
                                            : Colors.blue),
                          
                          child: Text(widget.msg.sender == widget.currentUser?"Cancel Invitation":"Join Group",
                            style: TextStyle(
                                      color: widget.msg.sender == widget.currentUser
                                          ? Colors.blue
                                          : Colors.white),))
                          ,
                          if(widget.msg.sender != widget.currentUser)
                          SizedBox(width: 10,),
                          if(widget.msg.sender != widget.currentUser)
                          OutlinedButton(onPressed: (){
                                Provider.of<ChatProvider>(context,
                                                    listen: false)
                                                .deleteMessage(
                                                    widget.msg, widget.currentUser);
                          },
                          style:   OutlinedButton.styleFrom(
                                  
                                        side: BorderSide(
                                          color:
                                              Colors.red.shade300, 
                                          width: 2, 
                                        ),
                                      ),
                           child: Text("Reject",style: TextStyle(color: Colors.red.shade300),))
                                                ],)
                          ],),
                        ),
                        )
                    ],
      ),
    )
:
     widget.isImage
        ? Container(
            child: Row(
              mainAxisAlignment: widget.msg.sender == widget.currentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: widget.msg.sender == widget.currentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                            imageUrl:
                                "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${widget.msg.message}/view?project=662e8e5c002f2d77a17c&mode=admin",
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            formatDate(widget.msg.timestamp),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        widget.msg.sender == widget.currentUser
                            ? widget.msg.isSeenByReceiver
                                ? Icon(
                                    Icons.check_circle_outlined,
                                    size: 16,
                                    color: kPrimaryColor,
                                  )
                                : Icon(
                                    Icons.check_circle_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  )
                            : SizedBox()
                      ],
                    )
                  ],
                )
              ],
            ),
          )
        : Container(
            padding: EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: widget.msg.sender == widget.currentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: widget.msg.sender == widget.currentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                              color: widget.msg.sender == widget.currentUser
                                  ? kPrimaryColor
                                  : kSecondaryColor,
                              borderRadius: BorderRadius.only(
                                  bottomLeft:
                                      widget.msg.sender == widget.currentUser
                                          ? Radius.circular(20)
                                          : Radius.circular(2),
                                  bottomRight:
                                      widget.msg.sender == widget.currentUser
                                          ? Radius.circular(2)
                                          : Radius.circular(20),
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20))),
                          child: Text(
                            widget.msg.message,
                            style: TextStyle(
                                color: widget.msg.sender == widget.currentUser
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            formatDate(widget.msg.timestamp),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                        widget.msg.sender == widget.currentUser
                            ? widget.msg.isSeenByReceiver
                                ? Icon(
                                    Icons.check_circle_outlined,
                                    size: 16,
                                    color: kPrimaryColor,
                                  )
                                : Icon(
                                    Icons.check_circle_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  )
                            : SizedBox()
                      ],
                    )
                  ],
                )
              ],
            ),
          );
  }
}

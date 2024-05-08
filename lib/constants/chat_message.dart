import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/constants/formate_date.dart';
import 'package:realtime_chatapp_appwrite/models/message_model.dart';

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
    return widget.isImage
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

import 'package:realtime_chatapp_appwrite/models/user_data.dart';

class GroupMessageModel {
  String messageId;
  String groupId;
  String message;
  String senderId;
  DateTime timestamp;
  bool? isImage;
  List<UserData> userData;

  GroupMessageModel({
    required this.messageId,
    required this.groupId,
    required this.message,
    required this.senderId,
    required this.timestamp,
    this.isImage,
    required this.userData,
  });

  // factory function to convert json to Group Message Model
  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
        messageId: map["\$id"],
        groupId: map["groupId"],
        message: map["message"],
        senderId: map["senderId"],
        isImage:  map["isImage"]??false,
        timestamp:DateTime.parse( map["timestamp"]??"2024-01-01"),
        userData: List<UserData>.from(map["userData"].map((e)=> UserData.toMap(e)) ?? []));
  }
}

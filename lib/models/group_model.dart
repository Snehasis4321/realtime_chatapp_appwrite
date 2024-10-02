import 'package:realtime_chatapp_appwrite/models/user_data.dart';

class GroupModel {
  String groupId;
  String admin;
  String groupName;
  String groupDesc;
  String? image;
  bool isPublic;
  List<String> members;
  List<UserData> userData;

  GroupModel(
      {required this.groupId,
      required this.groupName,
      required this.groupDesc,
      required this.admin,
      this.image,
      required this.isPublic,
      required this.members,
      required this.userData});

  //  parse the json to group model object
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
        groupId: map["\$id"],
        groupName: map["group_name"],
        groupDesc: map["group_desc"],
        image:  map["image"],
        admin: map["admin"],
        isPublic: map["isPublic"],
        members: List<String>.from(map["members"] ?? []),
        userData: List<UserData>.from(map["userData"].map((e)=> UserData.toMap(e)) ?? []));
  }
}

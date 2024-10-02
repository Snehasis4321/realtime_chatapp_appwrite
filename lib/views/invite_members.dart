import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/models/group_model.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class InviteMembers extends StatefulWidget {
  const InviteMembers({super.key});

  @override
  State<InviteMembers> createState() => _InviteMembersState();
}

class _InviteMembersState extends State<InviteMembers> {
  TextEditingController _searchController = TextEditingController();
  late DocumentList searchedUsers = DocumentList(total: -1, documents: []);
  Set<String> selectedUserIds = {};

// handle the search
  void _handleSearch() {
    searchUsers(
            searchItem: _searchController.text,
            userId:
                Provider.of<UserDataProvider>(context, listen: false).getUserId)
        .then((value) {
      if (value != null) {
        setState(() {
          searchedUsers = value;
        });
      } else {
        setState(() {
          searchedUsers = DocumentList(total: 0, documents: []);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    GroupModel groupData= ModalRoute.of(context)!.settings.arguments as GroupModel;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Invite Users",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(68),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: kSecondaryColor,
                      borderRadius: BorderRadius.circular(6)),
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) => _handleSearch(),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter phone number"),
                      )),
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          _handleSearch();
                        },
                      )
                    ],
                  ),
                ),
              ],
            )),
      ),
      body: searchedUsers.total == -1
          ? Center(
              child: Text("Use the search box to search users."),
            )
          : searchedUsers.total == 0
              ? Center(
                  child: Text("No users found"),
                )
              : ListView.builder(
                  itemCount: searchedUsers.documents.length,
                  itemBuilder: (context, index) {
                    final user = searchedUsers.documents[index];
                    final userId = user.$id;
                    final isSelected = selectedUserIds.contains(userId);
                    return ListTile(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedUserIds.remove(userId);
                          } else {
                            selectedUserIds.add(userId);
                          }
                        });
                      },
                      leading: CircleAvatar(
                        backgroundImage: user.data["profile_pic"] != null &&
                                user.data["profile_pic"] != ""
                            ? NetworkImage(
                                "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${user.data["profile_pic"]}/view?project=662e8e5c002f2d77a17c&mode=admin")
                            : Image(image: AssetImage("assets/user.png")).image,
                      ),
                      title: Text(user.data["name"] ?? "No Name"),
                      subtitle: Text(user.data["phone_no"] ?? ""),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
      floatingActionButton: selectedUserIds.length > 0
          ? GestureDetector(
            onTap: (){
              showDialog(context: context, builder: (context)=> AlterInvite(selectedUserIds: selectedUserIds, groupData:groupData  ));
            },
            child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: kPrimaryColor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  "Add ${selectedUserIds.length} member${selectedUserIds.length > 1 ? "s" : ""}",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          )
          : SizedBox(),
    );
  }
}

class AlterInvite extends StatefulWidget {
   final Set<String> selectedUserIds;
 final GroupModel groupData;
  const AlterInvite({super.key, required this.selectedUserIds,required this.groupData});

  @override
  State<AlterInvite> createState() => _AlterInviteState();
}

class _AlterInviteState extends State<AlterInvite> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:  Text("Procced to invite"),
      content: Text("Once the user accept the invite they will join the group."),
      actions: [
        TextButton(onPressed: (){
          Navigator.pop(context);
        }, child: Text("Cancel")),
        TextButton(onPressed: ()async{
          
          String currentUserId=Provider.of<UserDataProvider>(context,listen: false).getUserId;
          for(String id in widget.selectedUserIds){
        await  createNewChat(message: jsonEncode({
            "name": widget.groupData.groupName,
            "id": widget.groupData.groupId,
            "desc": widget.groupData.groupDesc,
            "image":widget.groupData.image
          }), senderId: currentUserId, receiverId: id, isImage: false, isGroupInvite: true);
          }
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        }, child: Text("Invite")),
      ],
    );
  }
}

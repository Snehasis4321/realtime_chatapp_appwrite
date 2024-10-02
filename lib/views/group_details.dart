import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/constants/memberCalculate.dart';
import 'package:realtime_chatapp_appwrite/models/group_model.dart';

class GroupDetails extends StatefulWidget {
  const GroupDetails({super.key});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  @override
  Widget build(BuildContext context) {
      final GroupModel groupData= ModalRoute.of(context)!.settings.arguments as GroupModel;
    return Scaffold( appBar:  AppBar(
            backgroundColor: kBackgroundColor,
            leadingWidth: 40,
            scrolledUnderElevation: 0,
            elevation: 0,
            title: Row(
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
              Text("Description :",style: TextStyle(fontWeight: FontWeight.w600),),
              SizedBox(height: 4,),
              Text(groupData.groupDesc??""),
              SizedBox(height: 4,),
              Divider(),
              SizedBox(height: 8,),
              Text("Members :",style: TextStyle(fontWeight: FontWeight.w600),),
              Column(children: 
              groupData.userData.map((e)=> Card(
                child: ListTile(
                  leading:   CircleAvatar(
                  backgroundImage: e.profilePic == "" ||
                          e.profilePic == null
                      ? Image(
                          image: AssetImage("assets/user.png"),
                        ).image
                      : CachedNetworkImageProvider(
                          "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${e.profilePic}/view?project=662e8e5c002f2d77a17c&mode=admin"),
                ),
                  title: Text(e.name??"No Name"),
                  subtitle: Text(e.userId==groupData.admin? "Admin":"Member"),
                ),
              )).toList(),)

            ],),
          ),
          );
  }
}
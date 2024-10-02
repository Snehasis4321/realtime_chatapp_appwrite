
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class ExploreGroups extends StatefulWidget {
  const ExploreGroups({super.key});

  @override
  State<ExploreGroups> createState() => _ExploreGroupsState();
}

class _ExploreGroupsState extends State<ExploreGroups> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Public Groups"),),
    body:  FutureBuilder(future:  getPublicGroups(),
    builder: (context, snapshot) {
      if(snapshot.connectionState==ConnectionState.waiting){
        return Center(child: CircularProgressIndicator());
      }
      else if(snapshot.hasError){
        return Text("No groups to show");
      }
      else{
        return ListView.builder(itemCount:  snapshot.data!.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading:  CircleAvatar(
                  backgroundImage: snapshot.data![index].data["image"] == "" ||
                          snapshot.data![index].data["image"] == null
                      ? Image(
                          image: AssetImage("assets/user.png"),
                        ).image
                      : CachedNetworkImageProvider(
                          "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${snapshot.data![index].data["image"]}/view?project=662e8e5c002f2d77a17c&mode=admin"),
                )
            ,title: Text(snapshot.data![index].data["group_name"]),
          subtitle:  Text(snapshot.data![index].data["group_desc"]),
          trailing: ElevatedButton(child: Text("Join Group"), onPressed: ()async{
            await addUserToGroup(groupId: snapshot.data![index].data["\$id"], currentUser: Provider.of<UserDataProvider>(context,listen: false).getUserId).
            then((value){
              if(value){
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Group Joined Successfully.")));
              }

            });


          },),
          );
        },
        );
      }
    },
    ),
    );
  }
}
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/controllers/local_saved_data.dart';
import 'package:realtime_chatapp_appwrite/providers/chat_provider.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Profile"),
          ),
          body: ListView(
            children: [
              ListTile(
                onTap: () => Navigator.pushNamed(context, "/update",
                    arguments: {"title": "edit"}),
                leading: CircleAvatar(
                  backgroundImage: value.getUserProfile != null ||
                          value.getUserProfile != ""
                      ? CachedNetworkImageProvider(
                          "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${value.getUserProfile}/view?project=662e8e5c002f2d77a17c&mode=admin")
                      : Image(
                          image: AssetImage("assets/user.png"),
                        ).image,
                ),
                title: Text(value.getUserName),
                subtitle: Text(value.getUserNumber),
                trailing: Icon(Icons.edit_outlined),
              ),
              Divider(),
              ListTile(
                onTap: () async {
                  await updateOnlineStatus(
                      status: false,
                      userId:
                          Provider.of<UserDataProvider>(context, listen: false)
                              .getUserId);
                  await LocalSavedData.clearAllData();
                  Provider.of<UserDataProvider>(context, listen: false)
                      .clearAllProvider();
                  Provider.of<ChatProvider>(context, listen: false)
                      .clearChats();
                  await logoutUser();
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/login", (route) => false);
                },
                leading: Icon(Icons.logout_outlined),
                title: Text("Logout"),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("About"),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:appwrite/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class SearchUsers extends StatefulWidget {
  const SearchUsers({super.key});

  @override
  State<SearchUsers> createState() => _SearchUsersState();
}

class _SearchUsersState extends State<SearchUsers> {
  TextEditingController _searchController = TextEditingController();
  late DocumentList searchedUsers = DocumentList(total: -1, documents: []);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search Users",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(110),
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
                ListTile(
                  onTap: () => Navigator.pushNamed(context,"/modify_group"),
                  leading: Icon(Icons.group_add_outlined),
                  title: Text("Create new group"),
                  trailing: Icon(
                    Icons
                        .arrow_forward_ios, // Add an arrow for navigation indication
                    color: Colors.grey, // Subtle arrow color
                    size: 18,
                  ),
                )
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
                    return ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, "/chat",
                            arguments: UserData.toMap(
                                searchedUsers.documents[index].data));
                      },
                      leading: CircleAvatar(
                        backgroundImage: searchedUsers
                                        .documents[index].data["profile_pic"] !=
                                    null &&
                                searchedUsers
                                        .documents[index].data["profile_pic"] !=
                                    ""
                            ? NetworkImage(
                                "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${searchedUsers.documents[index].data["profile_pic"]}/view?project=662e8e5c002f2d77a17c&mode=admin")
                            : Image(image: AssetImage("assets/user.png")).image,
                      ),
                      title: Text(searchedUsers.documents[index].data["name"] ??
                          "No Name"),
                      subtitle: Text(
                          searchedUsers.documents[index].data["phone_no"] ??
                              ""),
                    );
                  },
                ),
    );
  }
}

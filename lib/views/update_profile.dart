import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/constants/colors.dart';
import 'package:realtime_chatapp_appwrite/controllers/appwrite_controllers.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  FilePickerResult? _filePickerResult;

  late String? imageId = "";
  late String? userId = "";

  final _namekey = GlobalKey<FormState>();

  @override
  void initState() {
    // try to load the data from local database
    Future.delayed(Duration.zero, () {
      userId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
      Provider.of<UserDataProvider>(context, listen: false)
          .loadUserData(userId!);
      imageId =
          Provider.of<UserDataProvider>(context, listen: false).getUserProfile;
    });

    super.initState();
  }

// to open file picker
  void _openFilePicker() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    setState(() {
      _filePickerResult = result;
    });
  }

// upload user profile image and save it to bucket and database
  Future uploadProfileImage() async {
    try {
      if (_filePickerResult != null && _filePickerResult!.files.isNotEmpty) {
        PlatformFile file = _filePickerResult!.files.first;
        final fileByes = await File(file.path!).readAsBytes();
        final inputfile =
            InputFile.fromBytes(bytes: fileByes, filename: file.name);

        // if image already exist for the user profile or not
        if (imageId != null && imageId != "") {
          // then update the image
          await updateImageOnBucket(image: inputfile, oldImageId: imageId!)
              .then((value) {
            if (value != null) {
              imageId = value;
            }
          });
        }

        // create new image and upload to bucket
        else {
          await saveImageToBucket(image: inputfile).then((value) {
            if (value != null) {
              imageId = value;
            }
          });
        }
      } else {
        print("something went wrong");
      }
    } catch (e) {
      print("error on uploading image :$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> datapassed =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return Consumer<UserDataProvider>(
      builder: (context, value, child) {
        _nameController.text = value.getUserName;
        _phoneController.text = value.getUserNumber;
        imageId = value.getUserProfile;
        print("set image id to this $imageId");
        return Scaffold(
          appBar: AppBar(
            title:
                Text(datapassed["title"] == "edit" ? "Update" : "Add Details"),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      _openFilePicker();
                    },
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 120,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _filePickerResult != null
                            ? Image(
                                    image: FileImage(File(
                                        _filePickerResult!.files.first.path!)))
                                .image
                            : value.getUserProfile != "" &&
                                    value.getUserProfile != null
                                ? CachedNetworkImageProvider(
                                    "https://cloud.appwrite.io/v1/storage/buckets/662faabe001a20bb87c6/files/${value.getUserProfile}/view?project=662e8e5c002f2d77a17c&mode=admin")
                                : null,
                      ),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(30)),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                            ),
                          ))
                    ]),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: kSecondaryColor,
                        borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.all(6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Form(
                      key: _namekey,
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) return "Cannot be empty";
                          return null;
                        },
                        controller: _nameController,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter you name"),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: kSecondaryColor,
                        borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.all(6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TextFormField(
                      controller: _phoneController,
                      enabled: false,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: "Phone Number"),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print("current image id is $imageId");
                        if (_namekey.currentState!.validate()) {
                          // upload the image if file is picked
                          if (_filePickerResult != null) {
                            await uploadProfileImage();
                          }

                          // save the data to database user collection
                          await updateUserDetails(imageId ?? "",
                              userId: userId!, name: _nameController.text);

                          // navigate the user to the home route
                          Navigator.pushNamedAndRemoveUntil(
                              context, "/home", (route) => false);
                        }
                      },
                      child: Text(datapassed["title"] == "edit"
                          ? "Update"
                          : "Continue"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

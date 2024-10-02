import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:provider/provider.dart';
import 'package:realtime_chatapp_appwrite/controllers/local_saved_data.dart';
import 'package:realtime_chatapp_appwrite/main.dart';
import 'package:realtime_chatapp_appwrite/models/chat_data_model.dart';
import 'package:realtime_chatapp_appwrite/models/group_message_model.dart';
import 'package:realtime_chatapp_appwrite/models/message_model.dart';
import 'package:realtime_chatapp_appwrite/models/user_data.dart';
import 'package:realtime_chatapp_appwrite/providers/chat_provider.dart';
import 'package:realtime_chatapp_appwrite/providers/group_message_provider.dart';
import 'package:realtime_chatapp_appwrite/providers/user_data_provider.dart';
import 'package:http/http.dart' as http;

Client client = Client()
    .setEndpoint('https://cloud.appwrite.io/v1')
    .setProject('662e8e5c002f2d77a17c')
    .setSelfSigned(
        status: true); // For self signed certificates, only use for development

const String db = "662e8faa0023aee32aa2";
const String userCollection = "662e8fb6000c22d22075";
const String chatCollection = "663005fa00219227b219";
const String groupCollection = "66faffc6003b2312a584";
const String groupMsgCollection = "66fb00c800016ed39134";
const String storageBucket = "662faabe001a20bb87c6";

Account account = Account(client);
final Databases databases = Databases(client);
final Storage storage = Storage(client);
final Realtime realtime = Realtime(client);

RealtimeSubscription? subscription;
RealtimeSubscription? groupMsgSubscription;
// to subscribe to realtime changes
subscribeToRealtime({required String userId}) {
  subscription = realtime.subscribe([
    "databases.$db.collections.$chatCollection.documents",
    "databases.$db.collections.$userCollection.documents"
  ]);

  print("subscribing to realtime");

  subscription!.stream.listen((data) {
    print("some event happend");
    // print(data.events);
    // print(data.payload);
    final firstItem = data.events[0].split(".");
    final eventType = firstItem[firstItem.length - 1];
    print("event type is $eventType");
    if (eventType == "create") {
      Provider.of<ChatProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadChats(userId);
    } else if (eventType == "update") {
      Provider.of<ChatProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadChats(userId);
    } else if (eventType == "delete") {
      Provider.of<ChatProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadChats(userId);
    }
  });
}

// to subscribe to realtime changes
subscribeToRealtimeGroupMsg({required String userId}) {
  subscription = realtime.subscribe([
    "databases.$db.collections.$groupCollection.documents",
    "databases.$db.collections.$groupMsgCollection.documents"
  ]);

  print("subscribing to realtime");

  subscription!.stream.listen((data) {
    print("some event happend");
    // print(data.events);
    // print(data.payload);
    final firstItem = data.events[0].split(".");
    final eventType = firstItem[firstItem.length - 1];
    print("event type is $eventType");
    if (eventType == "create") {
      Provider.of<GroupMessageProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadAllGroupRequiredData(userId);
    } else if (eventType == "update") {
   Provider.of<GroupMessageProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadAllGroupRequiredData(userId);
    } else if (eventType == "delete") {
     Provider.of<GroupMessageProvider>(navigatorKey.currentState!.context,
              listen: false)
          .loadAllGroupRequiredData(userId);
    }
  });
}

// save phone number to database (while creating a new account)
Future<bool> savePhoneToDb(
    {required String phoneno, required String userId}) async {
  try {
    final response = await databases.createDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"phone_no": phoneno, "userId": userId});

    print(response);
    return true;
  } on AppwriteException catch (e) {
    print("Cannot save to user database :$e");
    return false;
  }
}

// check whether phone number exist in DB or not
Future<String> checkPhoneNumber({required String phoneno}) async {
  try {
    final DocumentList matchUser = await databases.listDocuments(
        databaseId: db,
        collectionId: userCollection,
        queries: [Query.equal("phone_no", phoneno)]);

    if (matchUser.total > 0) {
      final Document user = matchUser.documents[0];

      if (user.data["phone_no"] != null || user.data["phone_no"] != "") {
        return user.data["userId"];
      } else {
        print("no user exist on db");
        return "user_not_exist";
      }
    } else {
      print("no user exist on db");
      return "user_not_exist";
    }
  } on AppwriteException catch (e) {
    print("error on reading database $e");
    return "user_not_exist";
  }
}

// create a phone session , send otp to the phone number
Future<String> createPhoneSession({required String phone}) async {
  try {
    final userId = await checkPhoneNumber(phoneno: phone);
    if (userId == "user_not_exist") {
      // creating a new account
      final Token data =
          await account.createPhoneToken(userId: ID.unique(), phone: phone);

      // save the new user to user collection
      savePhoneToDb(phoneno: phone, userId: data.userId);
      return data.userId;
    }

    // if user is an existing user
    else {
      // create phone token for existing user
      final Token data =
          await account.createPhoneToken(userId: userId, phone: phone);
      return data.userId;
    }
  } catch (e) {
    print("error on create phone session :$e");
    return "login_error";
  }
}

// login with otp
Future<bool> loginWithOtp({required String otp, required String userId}) async {
  try {
    final Session session =
        await account.updatePhoneSession(userId: userId, secret: otp);
    print(session.userId);
    return true;
  } catch (e) {
    print("error on login with otp :$e");
    return false;
  }
}

// to check whether the session exist or not
Future<bool> checkSessions() async {
  try {
    final Session session = await account.getSession(sessionId: "current");
    print("session exist ${session.$id}");
    return true;
  } catch (e) {
    print("session does not exist please login");
    return false;
  }
}

// to logout the user and delete session
Future logoutUser() async {
  await account.deleteSession(sessionId: "current");
}

// load user data
Future<UserData?> getUserDetails({required String userId}) async {
  try {
    final response = await databases.getDocument(
        databaseId: db, collectionId: userCollection, documentId: userId);
    print("getting user data ");
    print(response.data);
    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setUserName(response.data["name"] ?? "");
    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setProfilePic(response.data["profile_pic"] ?? "");
    return UserData.toMap(response.data);
  } catch (e) {
    print("error in getting user data :$e");
    return null;
  }
}

// to update the user Data
Future<bool> updateUserDetails(
  String pic, {
  required String userId,
  required String name,
}) async {
  try {
    final data = await databases.updateDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"name": name, "profile_pic": pic});

    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setUserName(name);
    Provider.of<UserDataProvider>(navigatorKey.currentContext!, listen: false)
        .setProfilePic(pic);
    print(data);
    return true;
  } on AppwriteException catch (e) {
    print("cannot save to db :$e");
    return false;
  }
}

// upload and save image to storage bucket (create new image)
Future<String?> saveImageToBucket({required InputFile image}) async {
  try {
    final response = await storage.createFile(
        bucketId: storageBucket, fileId: ID.unique(), file: image);
    print("the response after save to bucket $response");
    return response.$id;
  } catch (e) {
    print("error on saving image to bucket :$e");
    return null;
  }
}

// update an image in bucket : first delete then create new
Future<String?> updateImageOnBucket(
    {required String oldImageId, required InputFile image}) async {
  try {
    // to delete the old image
    deleteImagefromBucket(oldImageId: oldImageId);

    // create a new image
    final newImage = saveImageToBucket(image: image);

    return newImage;
  } catch (e) {
    print("cannot update / delete image :$e");
    return null;
  }
}

// to only delete the image from the storage bucket

Future<bool> deleteImagefromBucket({required String oldImageId}) async {
  try {
    // to delete the old image
    await storage.deleteFile(bucketId: storageBucket, fileId: oldImageId);

    return true;
  } catch (e) {
    print("cannot update / delete image :$e");
    return false;
  }
}

// to search all the users from the database
Future<DocumentList?> searchUsers(
    {required String searchItem, required String userId}) async {
  try {
    final DocumentList users = await databases.listDocuments(
        databaseId: db,
        collectionId: userCollection,
        queries: [
          Query.search("phone_no", searchItem),
          Query.notEqual("userId", userId)
        ]);

    print("total match users ${users.total}");
    return users;
  } catch (e) {
    print("error on search users :$e");
    return null;
  }
}

// create a new chat and save to database
Future createNewChat(
    {required String message,
    required String senderId,
    required String receiverId,
    required bool isImage,required bool isGroupInvite}) async {
  try {
    final msg = await databases.createDocument(
        databaseId: db,
        collectionId: chatCollection,
        documentId: ID.unique(),
        data: {
          "message": message,
          "senderId": senderId,
          "receiverId": receiverId,
          "timestamp": DateTime.now().toIso8601String(),
          "isSeenbyReceiver": false,
          "isImage": isImage,
          "userData": [senderId, receiverId],
          "isGroupInvite":isGroupInvite
        });

    print("message send");
    return true;
  } catch (e) {
    print("failed to send message :$e");
    return false;
  }
}

// to delete the chat from database chat collection
Future deleteCurrentUserChat({required String chatId}) async {
  try {
    await databases.deleteDocument(
        databaseId: db, collectionId: chatCollection, documentId: chatId);
  } catch (e) {
    print("error on deleting chat message : $e");
  }
}

// edit our chat message and update to database
Future editChat({
  required String chatId,
  required String message,
}) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: chatCollection,
        documentId: chatId,
        data: {"message": message});
    print("message updated");
  } catch (e) {
    print("error on editing message :$e");
  }
}

// to list all the chats belonging to the current user
Future<Map<String, List<ChatDataModel>>?> currentUserChats(
    String userId) async {
  try {
    var results = await databases
        .listDocuments(databaseId: db, collectionId: chatCollection, queries: [
      Query.or(
          [Query.equal("senderId", userId), Query.equal("receiverId", userId)]),
      Query.orderDesc("timestamp"),
      Query.limit(2000)
    ]);

    final DocumentList chatDocuments = results;

    print(
        "chat documents ${chatDocuments.total} and documents ${chatDocuments.documents.length}");
    Map<String, List<ChatDataModel>> chats = {};

    if (chatDocuments.documents.isNotEmpty) {
      for (var i = 0; i < chatDocuments.documents.length; i++) {
        var doc = chatDocuments.documents[i];
        String sender = doc.data["senderId"];
        String receiver = doc.data["receiverId"];

        MessageModel message = MessageModel.fromMap(doc.data);

        List<UserData> users = [];
        for (var user in doc.data["userData"]) {
          users.add(UserData.toMap(user));
        }

        String key = (sender == userId) ? receiver : sender;

        if (chats[key] == null) {
          chats[key] = [];
        }
        chats[key]!.add(ChatDataModel(message: message, users: users));
      }
    }

    return chats;
  } catch (e) {
    print("error in reading current user chats :$e");
    return null;
  }
}

// to update isSeen message status
Future updateIsSeen({required List<String> chatsIds}) async {
  try {
    for (var chatid in chatsIds) {
      await databases.updateDocument(
          databaseId: db,
          collectionId: chatCollection,
          documentId: chatid,
          data: {"isSeenbyReceiver": true});
      print("update is seen");
    }
  } catch (e) {
    print("error in update isseen :$e");
  }
}

// to update the online status
Future updateOnlineStatus(
    {required bool status, required String userId}) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"isOnline": status});
    print("updated user online status $status ");
  } catch (e) {
    print("unable to update online status : $e");
  }
}

// to save users device token to user collection
Future saveUserDeviceToken(String token, String userId) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: userCollection,
        documentId: userId,
        data: {"device_token": token});
    print("device token saved to db");

    return true;
  } catch (e) {
    print("cannot save device token :$e");
    return false;
  }
}

// to send notification to other user
Future sendNotificationtoOtherUser({
  required String notificationTitle,
  required String notificationBody,
  required String deviceToken,
}) async {
  try {
    print("sending notification");
    final Map<String, dynamic> body = {
      "deviceToken": deviceToken,
      "message": {"title": notificationTitle, "body": notificationBody},
    };

    final response = await http.post(
        Uri.parse("https://6639e5cdc5c67686b510.appwrite.global/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    if (response.statusCode == 200) {
      print("notification send to other user");
    }
  } catch (e) {
    print("notification cannot be sent");
  }
}

// Group Functions
// create a new group
Future<bool> createNewGroup(
    {required String currentUser,
    required String groupName,
    required String groupDesc,
    bool? isOpen,
    required String image}) async {
  try {
    await databases.createDocument(
        databaseId: db,
        collectionId: groupCollection,
        documentId: ID.unique(),
        data: {
          "admin": currentUser,
          "group_name": groupName,
          "group_desc": groupDesc,
          "image": image,
          "isPublic": isOpen,
          "members": [currentUser],
          "userData": [currentUser]
        });
    return true;
  } catch (e) {
    print("Failed to create new group $e");
    return false;
  }
}

Future<bool> updateExistingGroup(
    {required String groupId,
    required String groupName,
    required String groupDesc,
    bool? isOpen,
    required String image}) async {
  try {
    await databases.updateDocument(
        databaseId: db,
        collectionId: groupCollection,
        documentId: groupId,
        data: {
          "group_name": groupName,
          "group_desc": groupDesc,
          "image": image,
          "isPublic": isOpen,
        });
    return true;
  } catch (e) {
    print("Failed to update the group $e");
    return false;
  }
}

// read all the groups current user is joined now.
Future<DocumentList?> readAllGroups({required String currentUserId}) async {
  try {
    var result = await databases.listDocuments(
        databaseId: db,
        collectionId: groupCollection,
        queries: [Query.equal("members", currentUserId), Query.limit(100)]);

    return result;
  } catch (e) {
    print("error on reading group $e");
    return null;
  }
}

// GROUP MESSAGES
// send a message to the group
Future<bool> sendGroupMessage(
    {required String groupId,
    required String message,
    required String senderId,
    bool? isImage}) async {
  try {
    await databases.createDocument(
        databaseId: db,
        collectionId: groupMsgCollection,
        documentId: ID.unique(),
        data: {
          "groupId": groupId,
          "message": message,
          "senderId": senderId,
          "timestamp": DateTime.now().toIso8601String(),
          "isImage": isImage ?? false,
          "userData": [senderId]
        });
        return true;
  } catch (e) {
    print("error on sending group message ");
  return false;
  }
}

// update the group message
Future<bool> updateGroupMessage({required String messageId,required String newMessage})async{
  try{
    await databases.updateDocument(databaseId: db,
     collectionId: groupMsgCollection, documentId: messageId
     ,data:  {
      "message":newMessage
     });
     return true;
  }
  catch(e){
    print("error on updating group chat :$e");
    return false;
  }
}

// delete the specific group message
Future deleteGroupMessage({required String messageId})async{
  try{
    await databases.deleteDocument(databaseId: db, 
    collectionId: groupMsgCollection, documentId: messageId);
  }
  catch(e){
    print("error in deleting group message :$e");
  }
}

// reading all the group messages
Future<Map<String, List<GroupMessageModel>>?> readGroupMessages(
    {required List<String> groupIds}) async {
  try {
    var results = await databases
        .listDocuments(databaseId: db, collectionId: groupMsgCollection, queries: [
          Query.equal("groupId",groupIds),
      Query.orderDesc("timestamp"),
      Query.limit(2000)
    ]);

    final DocumentList groupChatDocuments = results;

 
    Map<String, List<GroupMessageModel>> chats = {};

    if (groupChatDocuments.documents.isNotEmpty) {
      for (var i = 0; i < groupChatDocuments.documents.length; i++) {
        var doc = groupChatDocuments.documents[i];
      
        GroupMessageModel message = GroupMessageModel.fromMap(doc.data);
         String groupId = doc.data["groupId"];

        String key =groupId;

        if (chats[key] == null) {
          chats[key] = [];
        }
        chats[key]!.add(message);
      }
    }

    print("loaded chats ${chats.length}");

    return chats;
  } catch (e) {
    print("error in reading group chat messages :$e");
    return null;
  }
}

// to add the user to the specific group
Future<bool> addUserToGroup({required String groupId,required String currentUser})async{
  try{
    //  read the group members first
    final result= await databases.getDocument(databaseId: db,
     collectionId: groupCollection, documentId: groupId, queries: [Query.select(["members"])]);

     List existingMembers= result.data["members"];

     if(!existingMembers.contains(currentUser)){
      existingMembers.add(currentUser);
     }

    //  update the document of the specific group
    await databases.updateDocument(databaseId: db, 
    collectionId: groupCollection, documentId: groupId,
    data: {
      "members":existingMembers,
      "userData":existingMembers
    });
    return true;
  }
  catch(e){
    print("error on joining group :$e");
    return false;
  }
}

// to exit the specific group
Future<bool>exitGroup({required String groupId, required String currentUser})async{
   try{
    //  read the group members first
    final result= await databases.getDocument(databaseId: db,
     collectionId: groupCollection, documentId: groupId, queries: [Query.select(["members"])]);

     List existingMembers= result.data["members"];

     if(existingMembers.contains(currentUser)){
      existingMembers.remove(currentUser);
     }

    //  update the document of the specific group
    await databases.updateDocument(databaseId: db, 
    collectionId: groupCollection, documentId: groupId,
    data: {
      "members":existingMembers,
      "userData":existingMembers
    });
    return true;
  }
  catch(e){
    print("error on leaving group :$e");
    return false;
  }
}

// calculate the no of last unreadMessages
  Future<int> calculateUnreadMessages(String groupId, List<GroupMessageModel> groupMessages) async {
  Map<String, String> lastSeenMessages = await LocalSavedData(). getLastSeenMessages();
  String? lastSeenMessageId = lastSeenMessages[groupId];

  if (lastSeenMessageId == null) {
    return groupMessages.length; 
  }

  int unreadCount = groupMessages.indexWhere((message) => message.messageId == lastSeenMessageId);
  if (unreadCount == -1) {
    return groupMessages.length; 
  }

  return groupMessages.length - unreadCount - 1; 
}

// save last message seen in the group
 Future<void> updateLastMessageSeen(String groupId, String lastMessageSeenId) async {
  Map<String, String> lastSeenMessages = await LocalSavedData().getLastSeenMessages();
  print("last seen messages: $lastSeenMessages");
  lastSeenMessages[groupId] = lastMessageSeenId; 
  await LocalSavedData(). saveLastSeenMessages(lastSeenMessages); 
}

// list all public groups
Future <List<Document>> getPublicGroups()async{
  try{
    final results = await databases.listDocuments(
        databaseId: db, collectionId: groupCollection, queries: [
          Query.equal("isPublic", true),
        ]
    );
    print("result got");
    print(results.documents.length);
    return results.documents;
    
  }catch(e){
    print("error in getting public groups $e");
    return [];
  }
}


// send notifications to multiple users at once
Future sendMultipleNotificationtoOtherUser({
  required String notificationTitle,
  required String notificationBody,
  required List<String> deviceToken,
}) async {
  try {
    print("sending notification");
    final Map<String, dynamic> body = {
      "deviceToken": deviceToken,
      "message": {"title": notificationTitle, "body": notificationBody},
    };

    final response = await http.post(
        Uri.parse("https://6639e5cdc5c67686b510.appwrite.global/many"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    if (response.statusCode == 200) {
      print("notification send to other user");
    }
  } catch (e) {
    print("notification cannot be sent");
  }
}
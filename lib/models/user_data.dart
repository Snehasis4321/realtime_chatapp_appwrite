class UserData {
  final String? name;
  final String phone;
  final String userId;
  final String? profilePic;
  final String? deviceToken;
  final bool? isOnline;

  UserData(
      {this.name,
      required this.phone,
      required this.userId,
      this.profilePic,
      this.deviceToken,
      this.isOnline});

  // to convert Document data to userdata
  factory UserData.toMap(Map<String, dynamic> map) {
    return UserData(
        phone: map["phone_no"] ?? "",
        userId: map["userId"] ?? "",
        name: map["name"] ?? "",
        deviceToken: map["device_token"] ?? "",
        isOnline: map["isOnline"] ?? false,
        profilePic: map["profile_pic"] ?? "");
  }
}

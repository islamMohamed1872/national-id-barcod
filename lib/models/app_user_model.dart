class AppUserModel {
  final String uid;
  final String name;
  final String email;
  final int count;
  final String type;  // NEW

  AppUserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.count,
    required this.type,
  });
}

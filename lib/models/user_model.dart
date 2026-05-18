class UserModel {
  final String name;
  final String email;
  final String role; 
  final String uid;// "driver" or "passenger"

  UserModel({
    required this.name,
    required this.email,
    required this.role,
    required this.uid,
  });
}

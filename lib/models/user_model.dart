class UserModel {
  final String name;
  final String email;
  final String phone;
  final String role; 
  final String uid;// "driver" or "passenger"

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.uid,
  });
}

class UserModel {
  final String name;
  final String phone;
  final String role;
  final String uid;
  final bool isVerified;
  final String verificationStatus;
  final String? profileImage;
  final String? vehicleModel;
  final String? plateNumber;
  final String? profilePhotoUrl;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? licenseUrl;
  final String? carPhotoUrl;
  final bool isOnline;
  final double? lat;
  final double? lng;

  UserModel({
    required this.name,
    required this.phone,
    required this.role,
    required this.uid,
    this.isVerified = false,
    this.verificationStatus = '',
    this.profileImage,
    this.vehicleModel,
    this.plateNumber,
    this.profilePhotoUrl,
    this.idFrontUrl,
    this.idBackUrl,
    this.licenseUrl,
    this.carPhotoUrl,
    this.isOnline = false,
    this.lat,
    this.lng,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      uid: map['id'] ?? map['uid'] ?? '',
      isVerified: map['is_verified'] ?? false,
      verificationStatus: map['verification_status'] ?? '',
      profileImage: map['profile_image'],
      vehicleModel: map['vehicle_model'],
      plateNumber: map['plate_number'],
      profilePhotoUrl: map['profile_photo_url'],
      idFrontUrl: map['id_front_url'],
      idBackUrl: map['id_back_url'],
      licenseUrl: map['license_url'],
      carPhotoUrl: map['car_photo_url'],
      isOnline: map['is_online'] ?? false,
      lat: map['lat']?.toDouble(),
      lng: map['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'is_verified': isVerified,
      'verification_status': verificationStatus,
      'profile_image': profileImage,
      'vehicle_model': vehicleModel,
      'plate_number': plateNumber,
      'profile_photo_url': profilePhotoUrl,
      'id_front_url': idFrontUrl,
      'id_back_url': idBackUrl,
      'license_url': licenseUrl,
      'car_photo_url': carPhotoUrl,
      'is_online': isOnline,
      'lat': lat,
      'lng': lng,
    };
  }
}

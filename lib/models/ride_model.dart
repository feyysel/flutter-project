class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String from;
  final String to;
  final String time;
  final String price;
  final String seats;
  final int totalSeats;
  final int availableSeats;
  final String vehicleModel;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final String status;
  final String? createdAt;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.from,
    required this.to,
    required this.time,
    required this.price,
    required this.seats,
    required this.totalSeats,
    required this.availableSeats,
    this.vehicleModel = 'Economy',
    this.isOnline = false,
    this.lat,
    this.lng,
    this.status = 'active',
    this.createdAt,
  });

  factory RideModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RideModel(
      id: docId ?? map['id'] ?? '',
      driverId: map['driver_id'] ?? '',
      driverName: map['driver_name'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      time: map['time'] ?? '',
      price: map['price']?.toString() ?? '0',
      seats: map['seats']?.toString() ?? '0',
      totalSeats: map['total_seats'] ?? 0,
      availableSeats: map['available_seats'] ?? 0,
      vehicleModel: map['vehicle_model'] ?? 'Economy',
      isOnline: map['is_online'] ?? false,
      lat: map['lat']?.toDouble(),
      lng: map['lng']?.toDouble(),
      status: map['status'] ?? 'active',
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'from': from,
      'to': to,
      'time': time,
      'price': price,
      'seats': seats,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'vehicle_model': vehicleModel,
      'is_online': isOnline,
      'lat': lat,
      'lng': lng,
      'status': status,
    };
  }
}

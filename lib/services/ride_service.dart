import 'package:cloud_firestore/cloud_firestore.dart';

class RideService {
  static final _db = FirebaseFirestore.instance;

  // ADD RIDE (Driver)
  static Future<void> addRide({
    required String from,
    required String to,
    required String time,
    required double price,
    required String driverId,
    required String driverName,
    required String vehicleModel,
    required int seats,
  }) async {
    await _db.collection("posts").add({
      "from": from,
      "to": to,
      "time": time,
      "price": price,
      "driverId": driverId,
      "driverName": driverName,
      "vehicleModel": vehicleModel,
      "createdAt": FieldValue.serverTimestamp(),
      "totalSeats": seats,
      "availableSeats": seats,
      "isFull": false,
      "status": "active",            // active | full | completed
    });
  }

  // GET RIDES (Passenger)
  static Stream<QuerySnapshot> getRides() {
  return _db
      .collection("posts")
//.where("status", isEqualTo: "active")
      .snapshots();
}
}

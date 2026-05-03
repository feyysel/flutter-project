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
  }) async {
    await _db.collection("rides").add({
      "from": from,
      "to": to,
      "time": time,
      "price": price,
      "driverId": driverId,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // GET RIDES (Passenger)
  static Stream<QuerySnapshot> getRides() {
    return _db
        .collection("rides")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}

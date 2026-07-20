import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ride_service.dart';

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  _RideListScreenState createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  // ================= BOOK RIDE =================

  void showRideConfirmation(dynamic posts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 500,
          decoration: BoxDecoration(
            color: Color(0xFF11151F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                Text(
                  "PICKUP",
                  style: TextStyle(
                    color: Colors.grey,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 8),

                Text(
                  posts['from'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 25),

                Text(
                  "DESTINATION",
                  style: TextStyle(
                    color: Colors.grey,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  posts['to'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 35),

                Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0xFF11151F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              posts['vehicleModel'] ?? "Economy",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${posts['time'] ?? 'Now'} • ${posts['seats'] ?? '4'} seats",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${posts['price']} ETB",
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Est. Price",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[800],
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        posts['driverName'] ?? "Driver",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                      await bookRide(
                        rideId: posts.id,
                        driverId: posts['driverId'],
                        rideData: posts,
                      );
                    },
                    child: Text(
                      "Confirm Ride",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> bookRide({
    required String rideId,
    required String driverId,
    required dynamic rideData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final passengerDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final passengerData = passengerDoc.data();

    final driverDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(driverId)
        .get();

    final driverData = driverDoc.data();

    await FirebaseFirestore.instance.collection("ride_requests").add({
      "driverName": driverData?["name"],
      "driverPhone": driverData?["phone"],
      "driverPlate": driverData?["plateNumber"],
      "passengerPhone": passengerData?["phone"],
      "rideId": rideId,
      "driverId": driverId,
      "passengerId": user.uid,
      "passengerName": passengerData?["name"],
      "from": rideData["from"],
      "to": rideData["to"],
      "price": rideData["price"],
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
    .collection("posts")
    .doc(rideId)
    .update({

  "availableSeats": FieldValue.increment(-1),
});

final ride =
    await FirebaseFirestore.instance
        .collection("posts")
        .doc(rideId)
        .get();

final data = ride.data();

if (data != null &&
    data["availableSeats"] <= 0) {

  await ride.reference.update({
    "isFull": true,
  });
}

await FirebaseFirestore.instance
    .collection("posts")
    .doc(rideId)
    .update({

  "status": "completed",

});

    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": driverId,
      "title": "New Ride Request",
      "body": "${passengerData?["name"]} requested a ride",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Ride request sent"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050816),

      appBar: AppBar(
        backgroundColor: Color(0xFF050816),
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text(
          "Where to?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 10)
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search destination...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.location_on, color: Colors.purple),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        searchQuery = "";
                      });
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: RideService.getRides(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No rides available",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final rides = snapshot.data!.docs;

                  final filteredRides = rides.where((posts) {
                    final from = posts['from'].toString().toLowerCase();
                    final to = posts['to'].toString().toLowerCase();
                    return from.contains(searchQuery) ||
                        to.contains(searchQuery);
                  }).toList();

                  if (filteredRides.isEmpty) {
                    return Center(
                      child: Text(
                        "No matching rides",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredRides.length,
                    itemBuilder: (context, index) {
                      final posts = filteredRides[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Color(0xFF11151F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[800],
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${posts['from']} → ${posts['to']}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 5),

                                  Row(
                                    children: [
                                      Text(
                                        posts['driverName'] ?? "Driver",
                                        style:
                                            TextStyle(color: Colors.white70),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(

        color:
            (posts.data() as Map<String, dynamic>)
                    .containsKey('isOnline')
                ? posts['isOnline'] == true
                    ? Colors.green
                    : Colors.red
                : Colors.red,

        borderRadius:
            BorderRadius.circular(10),
      ),

      child: Text(

        (posts.data() as Map<String, dynamic>)
                .containsKey('isOnline')
            ? posts['isOnline'] == true
                ? "ONLINE"
                : "OFFLINE"
            : "OFFLINE",

        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
   ],
 ),

                                  SizedBox(height: 5),
                                  Text(
  "Seats: ${posts['availableSeats'] ?? 0}/${posts['totalSeats'] ?? posts['seats'] ?? 0}",
  style: TextStyle(
    color: Colors.grey,
    fontWeight: FontWeight.bold,
  ),
),

SizedBox(height: 5),

if ((posts['availableSeats'] ?? 0) == 0)
Container(
  padding: EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  ),
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text(
    "FULL",
    style: TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "${posts['price']} ETB",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 5),
                                ElevatedButton(
                                  onPressed:
((posts.data() as Map<String, dynamic>)
            .containsKey('isOnline')
        ? posts['isOnline'] == true
        : false) &&
(posts['availableSeats'] ?? 0) > 0
    ? () {
        showRideConfirmation(posts);
      }
    : null,
                                  child: Text("Book"),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
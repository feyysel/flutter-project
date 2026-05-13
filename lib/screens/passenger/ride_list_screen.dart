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
  Future<void> bookRide({
    required String rideId,
    required String driverId,
  }) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // GET PASSENGER DATA
    final passengerDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final passengerData = passengerDoc.data();

    // SAVE REQUEST
    await FirebaseFirestore.instance.collection("ride_requests")
        .add({
      "rideId": rideId,
      "driverId": driverId,
      "passengerId": user.uid,
      "passengerName":passengerData?["name"] ?? "",
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Ride requested successfully"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),

        title: Text(
          "Where to?",
          style: TextStyle(color: Colors.black),
        ),

        actions: [
          CircleAvatar(
            backgroundImage:
                NetworkImage( "https://i.pravatar.cc/150?img=3",
            ),
          ),

          SizedBox(width: 10)
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // SEARCH BAR
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    BorderRadius.circular(30),
              ),

              child: TextField(
                controller: searchController,

                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },

                decoration: InputDecoration(
                  hintText:"Search destination...",

                  border: InputBorder.none,
                  icon: Icon(
                    Icons.location_on,
                    color: Colors.purple,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(Icons.close),

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

            // ================= RIDE LIST =================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(

                stream: RideService.getRides(),

                builder: (context, snapshot) {

                  if (snapshot.connectionState ==ConnectionState.waiting) {
                    return Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {

                    return Center(
                      child:
                          Text("No rides available"),
                    );
                  }

                  final rides = snapshot.data!.docs;

                  // SEARCH FILTER
                  final filteredRides = rides.where((posts) {

                    final from =
                        posts['from']
                            .toString()
                            .toLowerCase();

                    final to =
                        posts['to']
                            .toString()
                            .toLowerCase();

                    return from.contains( searchQuery, ) ||to.contains( searchQuery, );

                  }).toList();

                  if (filteredRides.isEmpty) {

                    return Center(
                      child:
                          Text("No matching rides"),
                    );
                  }

                  return ListView.builder(
                    itemCount:
                        filteredRides.length,

                    itemBuilder:
                        (context, index) {

                      final posts =
                          filteredRides[index];

                      return Container(
                        margin:
                            EdgeInsets.only(
                          bottom: 15,
                        ),

                        padding:
                            EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color:
                              Colors.grey[100],

                          borderRadius:
                              BorderRadius
                                  .circular(16),
                        ),

                        child: Row(
                          children: [

                            CircleAvatar(
                              child: Icon(
                                Icons.person,
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  // ROUTE
                                  Text(
                                    "${posts['from']} → ${posts['to']}",

                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  SizedBox(height: 5),

                                  // DRIVER NAME
                                  Text(
                                    posts['driverName'] ??
                                        "Driver",
                                  ),

                                  SizedBox(height: 5),

                                  // TIME
                                  Text(
                                    "createdAt: ${posts['createdAt']}",
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              children: [

                                Text(
                                  "${posts['price']} ETB",

                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                SizedBox(height: 5),

                                ElevatedButton(

                                  onPressed: () {

                                    bookRide(
                                      rideId:
                                          posts.id,

                                      driverId:
                                          posts[
                                              'driverId'],
                                    );
                                  },

                                  child: Text(
                                    "Book",
                                  ),
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
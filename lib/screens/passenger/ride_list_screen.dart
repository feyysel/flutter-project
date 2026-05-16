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
          color: Colors.white,

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Center(
                child: Container(
                  width: 50,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey[300],

                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // PICKUP
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
                ),
              ),

              SizedBox(height: 25),

              // DESTINATION
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
                ),
              ),

              SizedBox(height: 35),

              // RIDE CARD
              Container(
                padding: EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.grey[100],

                  borderRadius:
                      BorderRadius.circular(24),
                ),

                child: Row(
                  children: [

                    Container(
                      padding: EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Icon(
                        Icons.directions_car,
                        size: 30,
                      ),
                    ),

                    SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            posts['vehicleModel']
                                ?? "Economy",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,

                              fontSize: 20,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "${posts['time'] ?? 'Now'} • ${posts['seats'] ?? '4'} seats",

                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,

                      children: [

                        Text(
                          "${posts['price']} ETB",

                          style: TextStyle(
                            color: Colors.deepPurple,

                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          "Est. Price",

                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // DRIVER
              Row(
                children: [

                  CircleAvatar(
                    radius: 22,

                    child: Icon(Icons.person),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      posts['driverName']
                          ?? "Driver",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              Spacer(),

              // CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                height: 65,

                child: ElevatedButton(

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.deepPurple,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                  ),

                  onPressed: () async {

                    Navigator.pop(context);

                    await bookRide(
                      rideId: posts.id,

                      driverId:
                          posts['driverId'],

                      rideData: posts,
                    );
                  },

                  child: Text(
                    "Confirm Ride",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
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

  final user =
      FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final passengerDoc =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

  final passengerData =
      passengerDoc.data();

  await FirebaseFirestore.instance
      .collection("ride_requests")
      .add({

    "rideId": rideId,

    "driverId": driverId,
    "passengerId": user.uid,

    "passengerName":
        passengerData?["name"],

    "from": rideData["from"],
    "to": rideData["to"],

    "price": rideData["price"],

    "status": "pending",

    "createdAt":
        FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context)
      .showSnackBar(

    SnackBar(
      backgroundColor: Colors.green,
      content:
          Text("Ride request sent"),
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

                                  /// DRIVER NAME
Row(
  children: [

    Text(
      posts['driverName'] ?? "Driver",
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
  onPressed:
      ((posts.data() as Map<String, dynamic>)
                  .containsKey('isOnline')
              ? posts['isOnline'] == true
              : false)
          ? () {

              showRideConfirmation(
                posts,
              );
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
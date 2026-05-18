import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_profile_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_screen.dart';

class DriverRidePostScreen extends StatefulWidget {
  @override
  State<DriverRidePostScreen> createState() =>
      _DriverRidePostScreenState();
}

class _DriverRidePostScreenState
    extends State<DriverRidePostScreen> {

  int currentIndex = 1;

  final fromController = TextEditingController();
  final toController = TextEditingController();
  final priceController = TextEditingController();
  final seatsController = TextEditingController();
  final timeController = TextEditingController();

  bool isLoading = false;

  // ================= POST RIDE =================
  Future<void> postRide() async {

    if (fromController.text.isEmpty ||
    toController.text.isEmpty ||
    priceController.text.isEmpty ||
    seatsController.text.isEmpty ||
    timeController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Fill all fields"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    final driverDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final driverData = driverDoc.data();

    await FirebaseFirestore.instance
        .collection("posts")
        .add({

      "driverId": user.uid,
      "driverName": driverData?["name"],
      //"vehicleModel": driverData?["vehicleModel"],

      "from": fromController.text,
      "to": toController.text,

     "price": priceController.text,

"seats": seatsController.text,
"isOnline": true,

"time": timeController.text,

"vehicleModel":
    driverData?["vehicleModel"] ?? "Economy",

      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      isLoading = false;
    });

    fromController.clear();
    toController.clear();
    priceController.clear();
    seatsController.clear();
    timeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Ride Posted Successfully"),
      ),
    );
  }

  Widget buildRideCard(dynamic ride) {

  return FutureBuilder<QuerySnapshot>(

    future: FirebaseFirestore.instance
        .collection("ride_requests")
        .where(
          "rideId",
          isEqualTo: ride.id,
        )
        .get(),

    builder: (context, requestSnapshot) {

      bool isBooked = false;
      dynamic request;

      if (requestSnapshot.hasData &&
          requestSnapshot.data!.docs.isNotEmpty) {

        isBooked = true;
        request =
            requestSnapshot.data!.docs.first;
      }

      return GestureDetector(

        onTap: () {

          showRideDetails(
            ride,
            request,
          );
        },

        child: Container(

          margin: EdgeInsets.only(bottom: 18),
          padding: EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Color(0xFF11151F),
            borderRadius:
                BorderRadius.circular(22),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  Expanded(
                    child: Text(
                      "${ride['from']} → ${ride['to']}",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(

                      color:
                          !isBooked
                              ? Colors.orange

                              : request['status']
                                          ==
                                      "accepted"
                                  ? Colors.green

                                  : request['status']
                                              ==
                                          "completed"
                                      ? Colors
                                          .deepPurple

                                      : Colors.blue,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: Text(

                      !isBooked
                          ? "OPEN"
                          : request['status']
                              .toUpperCase(),

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              Text(
                "Price: ${ride['price']} ETB",

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 5),

              Text(
                "Seats: ${ride['seats']}",

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 18),

              if (!isBooked)

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                    ),

                    onPressed: () async {

                      await FirebaseFirestore
                          .instance
                          .collection("posts")
                          .doc(ride.id)
                          .delete();

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(

                        SnackBar(
                          backgroundColor:
                              Colors.red,

                          content: Text(
                            "Ride cancelled",
                          ),
                        ),
                      );
                    },

                    child: Text("Cancel Ride"),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

void showRideDetails(
  dynamic ride,
  dynamic request,
) {

  showModalBottomSheet(

    context: context,

    backgroundColor: Color(0xFF050816),

    isScrollControlled: true,

    builder: (context) {

      return Padding(
        padding: EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Center(
              child: Container(
                width: 60,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
            ),

            SizedBox(height: 25),

            Text(
              "${ride['from']} → ${ride['to']}",

              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Price: ${ride['price']} ETB",

              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Seats: ${ride['seats']}",

              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),

            SizedBox(height: 25),

            if (request != null) ...[

              Text(
                "Passenger Details",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(height: 18),

              Text(
                "Name: ${request['passengerName']}",

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Status: ${request['status']}",

                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],

            SizedBox(height: 30),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFF050816),

      appBar: AppBar(
        backgroundColor: Color(0xFF050816),
        elevation: 0,
        title: Text("Post Ride"),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            textField(
              controller: fromController,
              hint: "From",
              icon: Icons.location_on,
            ),

            SizedBox(height: 18),

            textField(
              controller: toController,
              hint: "To",
              icon: Icons.location_pin,
            ),

            SizedBox(height: 18),

            textField(
              controller: priceController,
              hint: "Price",
              icon: Icons.attach_money,
            ),

            SizedBox(height: 18),

            textField(
              controller: seatsController,
              hint: "Available Seats",
              icon: Icons.event_seat,
            ),

            SizedBox(height: 18),

textField(
  controller: timeController,
  hint: "Ride Time (e.g 4:30 PM)",
  icon: Icons.access_time,
),

            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),

                onPressed: isLoading
                    ? null
                    : postRide,

                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        "Post Ride",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

          SizedBox(height: 35),

Align(
  alignment: Alignment.centerLeft,

  child: Text(
    "My Posted Rides",

    style: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
),

SizedBox(height: 20),

StreamBuilder<QuerySnapshot>(

  stream: FirebaseFirestore.instance
    .collection("posts")
    .where(
      "driverId",
      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
    )
    .snapshots(),

  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
  return Center(
    child: Text(
      snapshot.error.toString(),
      style: TextStyle(color: Colors.red),
    ),
  );
}

    if (snapshot.data!.docs.isEmpty) {

      return Padding(
        padding: EdgeInsets.only(top: 30),

        child: Text(
          "No posted rides yet",

          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    final rides = snapshot.data!.docs;

    return ListView.builder(

      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),

      itemCount: rides.length,

      itemBuilder: (context, index) {

        final ride = rides[index];

        return buildRideCard(ride);
      },
    );
  },
),

          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
  currentIndex: currentIndex,
  backgroundColor: Colors.white,
  selectedItemColor: Colors.deepPurple,
  unselectedItemColor: Colors.grey,
  type: BottomNavigationBarType.fixed,

  onTap: (index) {
    setState(() {
      currentIndex = index;
    });

    // HOME
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverHomeScreen(),
        ),
      );
    }

    // RIDE POST
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverRidePostScreen(),
        ),
      );
    }

    // EARNINGS
    else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverEarningsScreen(),
        ),
      );
    }

    // PROFILE
    else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverProfileScreen(),
        ),
      );
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: "Map",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle),
      label: "Ride Post",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet),
      label: "Earnings",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profile",
    ),
  ],
),
    );
  }

  // ================= TEXT FIELD =================
  Widget textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,

      style: TextStyle(color: Colors.white),

      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey),

        prefixIcon: Icon(
          icon,
          color: Colors.deepPurple,
        ),

        filled: true,
        fillColor: Color(0xFF11151F),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
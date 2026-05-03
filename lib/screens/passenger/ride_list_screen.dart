import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ride_service.dart';

class RideListScreen extends StatefulWidget {
  @override
  _RideListScreenState createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: Text("Where to?", style: TextStyle(color: Colors.black)),
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
          ),
          SizedBox(width: 10)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH BAR (UI unchanged)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search destination...",
                  border: InputBorder.none,
                  icon: Icon(Icons.location_on, color: Colors.purple),
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

            // 🚗 RIDE LIST (Firebase)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: RideService.getRides(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No rides available"));
                  }

                  final rides = snapshot.data!.docs;

                  // 🔍 FILTER SEARCH (without changing UI)
                  final filteredRides = rides.where((ride) {
                    final from = ride['from'].toString().toLowerCase();
                    final to = ride['to'].toString().toLowerCase();

                    return from.contains(searchQuery) ||
                        to.contains(searchQuery);
                  }).toList();

                  if (filteredRides.isEmpty) {
                    return Center(child: Text("No matching rides"));
                  }

                  return ListView.builder(
                    itemCount: filteredRides.length,
                    itemBuilder: (context, index) {
                      final ride = filteredRides[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${ride['from']} → ${ride['to']}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text("Time: ${ride['time']}"),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "${ride['price']} ETB",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                ElevatedButton(
                                  onPressed: () {
                                    print("Ride Selected");
                                  },
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

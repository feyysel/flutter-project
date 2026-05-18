import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState
    extends State<DriverVerificationScreen> {

  final profileUrlController =
      TextEditingController();

  final idFrontUrlController =
      TextEditingController();

  final idBackUrlController =
      TextEditingController();

  final licenseUrlController =
      TextEditingController();

  final carPhotoUrlController =
      TextEditingController();

  final plateController =
      TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Color(0xFFF7F7F7),
        elevation: 0,

        leading: BackButton(
          color: Colors.black,
        ),

        title: Text(
          "Identity Verification",

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          Container(
            margin: EdgeInsets.all(12),

            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: Text(
              "Step\n2 of\n3",

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // TOP PROGRESS
            Row(
              children: [

                Expanded(
                  child: Container(
                    height: 6,

                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Container(
                    height: 6,

                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Container(
                    height: 6,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 35),

            Text(
              "Secure Your Account",

              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Paste image URLs for your verification documents.",

              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                height: 1.5,
              ),
            ),

            SizedBox(height: 35),

            // ================= PROFILE PHOTO =================
            verificationCard(
              title: "Profile Photo",

              subtitle:
                  "Paste profile image URL.",

              icon: Icons.person_outline,

              child: Column(
                children: [

                  textField(
                    controller:
                        profileUrlController,

                    hint:
                        "https://example.com/profile.jpg",
                  ),

                  SizedBox(height: 15),

                  if (profileUrlController
                      .text
                      .isNotEmpty)

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      child: Image.network(
                        profileUrlController
                            .text,

                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,

                        errorBuilder:
                            (context, error,
                                stackTrace) {

                          return Container(
                            height: 180,

                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey.shade200,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),

                            child: Center(
                              child: Text(
                                "Invalid Image URL",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // ================= VEHICLE =================
            verificationCard(

              title: "Vehicle Information",

              subtitle:
                  "Enter plate number and car image URL.",

              icon: Icons.directions_car,

              child: Column(
                children: [

                  textField(
                    controller:
                        plateController,

                    hint: "Plate Number",
                  ),

                  SizedBox(height: 20),

                  textField(
                    controller:
                        carPhotoUrlController,

                    hint:
                        "https://example.com/car.jpg",
                  ),

                  SizedBox(height: 15),

                  if (carPhotoUrlController
                      .text
                      .isNotEmpty)

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      child: Image.network(
                        carPhotoUrlController
                            .text,

                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,

                        errorBuilder:
                            (context, error,
                                stackTrace) {

                          return Container(
                            height: 180,

                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey.shade200,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),

                            child: Center(
                              child: Text(
                                "Invalid Image URL",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // ================= ID CARD =================
            verificationCard(

              title: "Identity Card",

              subtitle:
                  "Front and back image URLs.",

              icon: Icons.badge_outlined,

              child: Column(
                children: [

                  textField(
                    controller:
                        idFrontUrlController,

                    hint:
                        "Front ID Image URL",
                  ),

                  SizedBox(height: 15),

                  textField(
                    controller:
                        idBackUrlController,

                    hint:
                        "Back ID Image URL",
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // ================= LICENSE =================
            verificationCard(

              title: "Driver’s License",

              subtitle:
                  "Paste license image URL.",

              icon:
                  Icons.workspace_premium_outlined,

              child: textField(
                controller:
                    licenseUrlController,

                hint:
                    "https://example.com/license.jpg",
              ),
            ),

            SizedBox(height: 25),

            // INFO BOX
            Container(
              padding: EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,

                borderRadius:
                    BorderRadius.circular(22),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.verified_user,
                    color: Colors.deepPurple,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      "Your data is securely stored for verification purposes only.",

                      style: TextStyle(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 35),

            // CONTINUE BUTTON
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
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                ),

                onPressed: () async {

                  if (profileUrlController
                          .text
                          .isEmpty ||
                      idFrontUrlController
                          .text
                          .isEmpty ||
                      idBackUrlController
                          .text
                          .isEmpty ||
                      licenseUrlController
                          .text
                          .isEmpty ||
                      carPhotoUrlController
                          .text
                          .isEmpty ||
                      plateController
                          .text
                          .isEmpty) {

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(

                      SnackBar(
                        backgroundColor:
                            Colors.red,

                        content: Text(
                          "Complete all verification fields",
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    isLoading = true;
                  });

                  try {

                    final user =
                        FirebaseAuth.instance
                            .currentUser;

                    await FirebaseFirestore
                        .instance
                        .collection("users")
                        .doc(user!.uid)
                        .update({

                      "profilePhotoUrl":
                          profileUrlController
                              .text,

                      "idFrontUrl":
                          idFrontUrlController
                              .text,

                      "idBackUrl":
                          idBackUrlController
                              .text,

                      "licenseUrl":
                          licenseUrlController
                              .text,

                      "carPhotoUrl":
                          carPhotoUrlController
                              .text,

                      "plateNumber":
                          plateController.text,

                      "verificationStatus":
                          "under_review",

                      "isVerified": false,
                    });

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(

                      SnackBar(
                        backgroundColor:
                            Colors.green,

                        content: Text(
                          "Documents submitted successfully",
                        ),
                      ),
                    );

                    Navigator.pop(context);

                  } catch (e) {

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(

                      SnackBar(
                        backgroundColor:
                            Colors.red,

                        content:
                            Text(e.toString()),
                      ),
                    );
                  }

                  setState(() {
                    isLoading = false;
                  });
                },

                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [

                          Text(
                            "Continue",

                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(width: 10),

                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================
  Widget textField({
    required TextEditingController
        controller,
    required String hint,
  }) {

    return TextField(
      controller: controller,

      onChanged: (value) {
        setState(() {});
      },

      decoration: InputDecoration(
        hintText: hint,

        filled: true,
        fillColor: Colors.grey.shade100,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget verificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {

    return Container(
      padding: EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(28),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Text(
                      title,

                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      subtitle,

                      style: TextStyle(
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              CircleAvatar(
                backgroundColor:
                    Colors.deepPurple.shade50,

                child: Icon(
                  icon,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          child,
        ],
      ),
    );
  }
}
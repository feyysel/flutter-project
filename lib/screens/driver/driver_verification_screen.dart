import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  File? profilePhoto;
  File? idFront;
  File? idBack;
  File? licensePhoto;
  File? carPhoto;

final plateController =
    TextEditingController();

bool isLoading = false;

  final picker = ImagePicker();

  Future<String> uploadFile(
  File file,
  String path,
) async {

  final ref = FirebaseStorage.instance
      .ref()
      .child(path);

  await ref.putFile(file);

  return await ref.getDownloadURL();
}

  // ================= PICK IMAGE =================
  Future<void> pickImage(Function(File) onPicked) async {

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {

      onPicked(File(picked.path));

      setState(() {});
    }
  }

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
              "To ensure safety on our platform, we need to verify your credentials. Please upload clear photos of the documents below.",

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
                  "Clear, forward-facing photo without sunglasses.",

              icon: Icons.person_outline,

              child: GestureDetector(

                onTap: () {
                  pickImage((file) {
                    profilePhoto = file;
                  });
                },

                child: Container(
                  height: 150,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),

                  child: profilePhoto == null
                      ? Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              "Upload Photo",

                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),

                          child: Image.file(
                            profilePhoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
            ),

            SizedBox(height: 25),

          // ================= PLATE NUMBER =================
verificationCard(

  title: "Vehicle Information",

  subtitle:
      "Enter vehicle plate number and upload front car image.",

  icon: Icons.directions_car,

  child: Column(
    children: [

      TextField(
        controller: plateController,

        decoration: InputDecoration(
          hintText: "Plate Number",

          filled: true,
          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),

            borderSide: BorderSide.none,
          ),
        ),
      ),

      SizedBox(height: 20),

      GestureDetector(

        onTap: () {

          pickImage((file) {
            carPhoto = file;
          });
        },

        child: Container(
          height: 180,

          decoration: BoxDecoration(
            color: Colors.grey.shade100,

            borderRadius:
                BorderRadius.circular(20),
          ),

          child: carPhoto == null

              ? Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Upload Car Front Photo",
                    ),
                  ],
                )

              : ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),

                  child: Image.file(
                    carPhoto!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    ],
  ),
),  

            // ================= ID CARD =================
            verificationCard(
              title: "Identity Card",
              subtitle:
                  "National ID or Passport. Front and back side.",

              icon: Icons.badge_outlined,

              child: Row(
                children: [

                  Expanded(
                    child: idBox(

                      title: "FRONT SIDE",

                      image: idFront,

                      onTap: () {
                        pickImage((file) {
                          idFront = file;
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: idBox(

                      title: "BACK SIDE",

                      image: idBack,

                      onTap: () {
                        pickImage((file) {
                          idBack = file;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // ================= LICENSE =================
            verificationCard(
              title: "Driver’s License",
              subtitle:
                  "Valid commercial or personal driving permit.",

              icon: Icons.workspace_premium_outlined,

              child: GestureDetector(

                onTap: () {
                  pickImage((file) {
                    licensePhoto = file;
                  });
                },

                child: Container(
                  height: 180,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,

                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: licensePhoto == null
                      ? Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  Colors.deepPurple,

                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 35,
                              ),
                            ),

                            SizedBox(height: 15),

                            Text(
                              "Tap to Capture",
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),

                          child: Image.file(
                            licensePhoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
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
                      "Your data is encrypted and stored securely. We only use this information for verification purposes and do not share it with third parties.",

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
                        BorderRadius.circular(30),
                  ),
                ),

                onPressed: () async {

  if (profilePhoto == null ||
      idFront == null ||
      idBack == null ||
      licensePhoto == null ||
      carPhoto == null ||
      plateController.text.isEmpty) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        backgroundColor: Colors.red,
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
        FirebaseAuth.instance.currentUser;

    // ================= UPLOAD FILES =================

    final profileUrl =
        await uploadFile(
      profilePhoto!,
      "verification/${user!.uid}/profile.jpg",
    );

    final frontIdUrl =
        await uploadFile(
      idFront!,
      "verification/${user.uid}/id_front.jpg",
    );

    final backIdUrl =
        await uploadFile(
      idBack!,
      "verification/${user.uid}/id_back.jpg",
    );

    final licenseUrl =
        await uploadFile(
      licensePhoto!,
      "verification/${user.uid}/license.jpg",
    );

    final carUrl =
        await uploadFile(
      carPhoto!,
      "verification/${user.uid}/car.jpg",
    );

    // ================= SAVE TO FIRESTORE =================

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({

      "profilePhotoUrl": profileUrl,

      "idFrontUrl": frontIdUrl,
      "idBackUrl": backIdUrl,

      "licenseUrl": licenseUrl,

      "carPhotoUrl": carUrl,

      "plateNumber":
          plateController.text,

      // STATUS
      "verificationStatus":
          "under_review",

      "isVerified": false,
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        backgroundColor: Colors.green,

        content: Text(
          "Documents submitted successfully",
        ),
      ),
    );

    Navigator.pop(context);

  } catch (e) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
      ),
    );
  }

  setState(() {
    isLoading = false;
  });
},

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

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
                      CrossAxisAlignment.start,

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

  // ================= ID BOX =================
  Widget idBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(
        height: 120,

        decoration: BoxDecoration(
          color: Colors.grey.shade100,

          borderRadius:
              BorderRadius.circular(18),
        ),

        child: image == null
            ? Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Icon(
                    Icons.file_copy_outlined,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 10),

                  Text(
                    title,

                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(18),

                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }
}
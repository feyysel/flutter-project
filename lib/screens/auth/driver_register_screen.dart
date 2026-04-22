import 'package:flutter/material.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final vehicleController = TextEditingController();
  final plateController = TextEditingController();

  bool agree = false;
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text("Driver Registration",
            style: TextStyle(color: Colors.black)),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Start your journey",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            Text(
              "Join as a driver and start earning by offering rides",
              style: TextStyle(color: Colors.grey[600]),
            ),

            SizedBox(height: 30),

            // ================= PERSONAL INFO =================
            _sectionTitle("Personal Information"),

            SizedBox(height: 15),

            _input(nameController, "Full Name", Icons.person),

            SizedBox(height: 15),

            _input(phoneController, "Phone Number", Icons.phone),

            SizedBox(height: 15),

            _input(emailController, "Email Address", Icons.email),

            SizedBox(height: 15),

           /* TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(hidePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
              ),
            ),*/

            SizedBox(height: 25),

            // ================= VEHICLE INFO =================
            _sectionTitle("Vehicle Information"),

            SizedBox(height: 15),

            _input(vehicleController, "Vehicle Model", Icons.directions_car),

            SizedBox(height: 15),

            _input(plateController, "License Plate", Icons.confirmation_number),

            SizedBox(height: 20),

            // INFO BOX
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "You will upload documents (license & vehicle) in the next step.",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),

            SizedBox(height: 20),

            // AGREEMENT
            Row(
              children: [
                Checkbox(
                  value: agree,
                  onChanged: (val) {
                    setState(() {
                      agree = val!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "I agree to the Terms of Service and Privacy Policy",
                  ),
                )
              ],
            ),

            SizedBox(height: 20),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                onPressed: agree
                    ? () {
                        print("Driver Registered");
                      }
                    : null,

                child: Text("Complete Registration"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET HELPERS =================

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          color: Colors.deepPurple,
        ),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _input(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
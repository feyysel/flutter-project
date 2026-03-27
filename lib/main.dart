import 'package:flutter/material.dart';
import 'home_page.dart'; // import your new file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ride Sharing App',
      home: HomePage(), // call HomePage from another file
    );
  }
}
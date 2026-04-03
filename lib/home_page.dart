import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  bool isMapFullScreen = false;

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () => showMessage("Menu clicked"),
        ),
        title: Text(
          "Safe and Reliable Rides",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => showMessage("Profile clicked"),
              child: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          )
        ],
      ),

      /// BODY
      body: Stack(
  children: [
    /// MAIN CONTENT (MAP + TOP)
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LOCATION
        Padding(
          padding: EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => showMessage("Change location"),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your current locations",
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple),
                    SizedBox(width: 5),
                    Text(
                      "Dire Dawa ,Ethiopia",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.keyboard_arrow_down)
                  ],
                ),
              ],
            ),
          ),
        ),

        /// MAP
        Expanded(
  child: GestureDetector(
    onTap: () {
      setState(() {
        isMapFullScreen = true;
        isSearching = false;
      });
    },
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: isMapFullScreen ? 0 : 16),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(isMapFullScreen ? 0 : 10),
        color: Colors.grey,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              "MAP AREA",
              style: TextStyle(color: Colors.white),
            ),
          ),

          /// BACK BUTTON (only when fullscreen)
          if (isMapFullScreen)
            Positioned(
              top: 40,
              left: 10,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    isMapFullScreen = false;
                  });
                },
                child: Icon(Icons.arrow_back),
              ),
            ),
        ],
      ),
    ),
  ),
),
      ],
    ),

    /// SEARCH PANEL (EXPANDS OVER MAP)
    AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      top: isMapFullScreen
    ? MediaQuery.of(context).size.height
    : (isSearching ? 0 : 220),
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            /// 🔍 SEARCH BAR
            TextField(
              controller: searchController,
              onTap: () {
                setState(() {
                  isSearching = true;
                });
              },
              decoration: InputDecoration(
                hintText: "Where do you wanna go?",
                prefixIcon:
                    Icon(Icons.location_on, color: Colors.red),
                suffixIcon: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      isSearching = false;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 20),

            /// OPTIONS (VISIBLE ONLY WHEN SEARCHING)
            if (isSearching) ...[
              ListTile(
                onTap: () => showMessage("Saved places"),
                leading: Icon(Icons.star),
                title: Text("Choose a saved place"),
              ),
              Divider(),
              ListTile(
                onTap: () => showMessage("Set destination"),
                leading: Icon(Icons.location_on),
                title: Text("Set destination on map"),
              ),
            ],
          ],
        ),
      ),
    ),

    /// 🔻 BOTTOM NAV (ALWAYS FIXED)
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavItem(Icons.home, "Home", 0),
            buildNavItem(Icons.history, "History", 1),
            buildNavItem(Icons.person, "Account", 2),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  Widget buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        showMessage("$label clicked");
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selectedIndex == index ? Colors.black : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: selectedIndex == index ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
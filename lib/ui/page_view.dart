import 'package:flutter/material.dart';

class NewPage {
  static Scaffold createScaffoldView(
      {required Widget appBarTitle, required Widget body}) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        automaticallyImplyLeading: false, //disables back button
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: appBarTitle,
      ),
      body: body,
    );
  }
}

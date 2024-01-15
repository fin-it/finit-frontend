import 'package:flutter/material.dart';

Widget buildExtendedCompose() => AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.linear,
      width: 130,
      height: 50,
      child: FloatingActionButton.extended(
        backgroundColor: Color.fromRGBO(43, 52, 153, 1),
        onPressed: () {},
        icon: Icon(
          Icons.edit,
          color: Colors.white,
        ),
        label: Center(
          child: Text(
            "New Data",
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
      ),
    );
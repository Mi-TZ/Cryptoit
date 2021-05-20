import 'package:flutter/material.dart';

Widget card1(
    {double width = double.infinity, double padding = 20, Widget child}) {
  return Container(
    margin: new EdgeInsets.all(10.0),
    width: width,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
        color: Color(0xFFF9FAFF),
        boxShadow: [
          //background color of box
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0, // soften the shadow
            spreadRadius: 0.0, //extend the shadow

          )
        ],
        borderRadius: BorderRadius.all(Radius.circular(15))),
    child: child,
  );
}

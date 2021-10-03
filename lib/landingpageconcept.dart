import 'package:flutter/material.dart';

{
    class LandingPage(){
      home: Scaffold(
        backgroundColor: Colors.blueGrey,
        appBar: AppBar(
          title: Text('Me Poor'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: Center(
          child: Image(
            image: AssetImage('images/diamond.png'),
        ),
      ),
    ),
  )
  );
}

import 'package:flutter/material.dart';



class Profile extends StatelessWidget {
  const Profile({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          color: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40)
          ),
          semanticContainer: true,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Image.asset(
            "assets/images/profile.png",
            height: 130,
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
        Text(
          "Cryptoit",
          style: TextStyle(fontSize: 24)
          ),

        Text(
          "@llastkrakw",
          style: TextStyle(fontSize: 12)
          ),

      ],
    );
  }
}
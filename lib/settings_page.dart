import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage(
      {this.savePreferences,
        });
  final Function savePreferences;


  @override
  SettingsPageState createState() => new SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  _confirmDeletePortfolio() {
    showDialog(
        context: context,
        builder: (context) {
          return new AlertDialog(
            title: new Text("Clear Portfolio?"),
            content: new Text("This will permanently delete all transactions."),
            actions: <Widget>[
              new FlatButton(
                  onPressed: () async {
                    await _deletePortfolio();
                    Navigator.of(context).pop();
                  },
                  child: new Text("Delete")),
              new FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: new Text("Cancel"))
            ],
          );
        });
  }

  Future<Null> _deletePortfolio() async {
    getApplicationDocumentsDirectory().then((Directory directory) {
      File jsonFile = new File(directory.path + "/portfolio.json");
      jsonFile.delete();
      portfolioMap = {};
    });
  }

  _exportPortfolio() {
    String text = json.encode(portfolioMap);
    GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return SafeArea(
        child: new Scaffold(
            key: _scaffoldKey,
            body: SingleChildScrollView(
              child: new Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 45
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  new Container(
                      padding: const EdgeInsets.only(left:50.0,right:50,top: 20,),
                      child: new Text('Udm Developers built the Cryptoit app as an Ad Supported app. This SERVICE is provided by Udm Developers at no cost and is intended for use as is.'

                          'This page is used to inform visitors regarding my policies with the collection, use, and disclosure of Personal Information if anyone decided to use my Service.'

                          'If you choose to use my Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that I collect is used for providing and improving the Service. I will not use or share your information with anyone except as described in this Privacy Policy.'

                          'The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible at Cryptoit unless otherwise defined in this Privacy Policy.'
                          'I value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and I cannot guarantee its absolute security.'
                      ))

                ],


                     ),
            ),
                ),
      );
    }));
  }



  _launchUrl(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String version = "";
  String buildNumber = "";
  _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  void initState() {
    super.initState();
    _getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: new LinearGradient(
            colors: [
              const Color(0xFFFAFAFA),
              const Color(0xFFe7eff9),
            ],
          ),
        ),
        child: new ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,vertical: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              padding: const EdgeInsets.all(18.0),
              child: new Text("Preferences",
                  style: Theme.of(context).textTheme.body2),
            ),

            new Container(

              child: new ListTile(
                leading: new Icon(Icons.format_list_numbered_rtl_rounded,color: Colors.blueAccent,),
                title: new Text("Abbreviate Numbers"),
                trailing: new Switch(
                  inactiveTrackColor: Colors.redAccent,
                    activeColor: Theme.of(context).accentColor,
                    value: shortenOn,
                    onChanged: (onOff) {
                      setState(() {
                        shortenOn = onOff;
                      });
                      widget.savePreferences();
                    }),
                onTap: () {
                  setState(() {
                    shortenOn = !shortenOn;
                  });
                  widget.savePreferences();
                },
              ),
            ),
            new Container(
              padding: const EdgeInsets.all(18.0),
              child: new Text("Options", style: Theme.of(context).textTheme.body2),
            ),
            new Container(

              child: new ListTile(
                title: new Text("Privacy Policy"),
                leading: new Icon(Icons.privacy_tip_rounded,color: Colors.deepPurpleAccent,),
                onTap: _exportPortfolio,
              ),
            ),

            new Container(

              child: new ListTile(
                title: new Text("Clear Portfolio"),
                leading: new Icon(Icons.delete_forever_rounded,color: Colors.redAccent,),
                onTap: _confirmDeletePortfolio,
              ),
            ),

            new Container(
              padding: const EdgeInsets.all(18.0),
              child: new Text("Credit", style: Theme.of(context).textTheme.body2),
            ),
            new Container(

              child: new ListTile(
                title: new RichText(
                    text: new TextSpan(
                        text: "",
                        style: Theme.of(context).textTheme.subhead,
                        children: <TextSpan>[
                          TextSpan(text: "Developed By", style: Theme.of(context).textTheme.subhead
                              .apply(color: Colors.black, fontWeightDelta: 2))
                        ]
                    )
                ),
                subtitle: new Text("Udm Developers"),
                leading: new Icon(Icons.favorite,color: Colors.redAccent,),
                onTap: () => _launchUrl("https://play.google.com/store/apps/developer?id=UDm+developers"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

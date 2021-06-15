import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'article.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';


import 'package:cryptoo/news/newsmain.dart';

class DetailScreen extends StatelessWidget {

  final Article article;

  const DetailScreen({Key key, this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF2F3F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color(0xFFF2F3F8),
          centerTitle: true,
          title: Text("Cryptoit News", style: TextStyle(fontWeight: FontWeight.w500,color: Colors.black)),
          leading:  IconButton(
              icon: Icon(Icons.arrow_back_ios),
              color: kTitleColor,
              iconSize: 20.0,
              onPressed: (){
                Navigator.pop(context);
              },
            ),
          actions: [
            IconButton(
                icon: Icon(Icons.share),
                color: kTitleColor,
                iconSize: 20.0,
                onPressed: () async{
                  Share.share(article.url);
                  print("yes");
                },
              ),

          ],
        ),

        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.open_in_new),
              heroTag: "go",
              onPressed: () async{

                  launch(article.url);
              },
            ),

          ],
        ),
        body: Container(
          margin: EdgeInsets.all(kDefaultPadding),
          padding: EdgeInsets.all(kDefaultPadding),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              gradient: new LinearGradient(
                colors: [
                  const Color(0xFFFAFAFA),
                  const Color(0xFFe7eff9),
                ],
              ),
            borderRadius: BorderRadius.circular(30)
          ),
          child: ListView(
            children: <Widget>[
              Container(
                    width: 300,
                    height: 190,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.network(article.urlToImage, fit: BoxFit.cover,),
              ),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Container(

                          child: Image.asset(
                            "assets/group.png",
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        "News :",
                        style:TextStyle(fontSize: 14)
                        ),

                    ],
                  ),

                ],
              ),
              SizedBox(height: 15,),
              Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    SizedBox(height: 10,),
                    Text(
                      article.title,
                      style:TextStyle(fontSize: 22)
                      ),

                    SizedBox(height: 20,),
                    Text(
                      article.content,
                      style: TextStyle(fontSize: 16,color: Colors.black54)

                    ),
                  ],
                ),
              )
            ],
          ),
        )
    );

  }
}


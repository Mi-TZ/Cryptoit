import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'package:cryptoo/news/newsmain.dart';
import 'package:cryptoo/news/detail.dart';
import 'package:cryptoo/news/article.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ArticleItem extends StatelessWidget {
  final Article article;
  InterstitialAd interstitialAd;


  void loadInterstitial () async {
    interstitialAd = InterstitialAd(
      // adUnitId: 'ca-app-pub-9746660700461224/1972272971',
      request: AdRequest(),
      listener: AdListener(
          onAdLoaded: (Ad ad) {
            interstitialAd.show();
          },
          onAdClosed: (Ad ad) {
            interstitialAd.dispose();
          }
      ),
    );

    interstitialAd.load();

  }
   ArticleItem({
    Key key,
    this.article,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        splashColor: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          loadInterstitial();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    article: article,
                  )));
        },
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
                children: [
              Container(
                height:  MediaQuery.of(context).size.height * 0.15,
                width:  MediaQuery.of(context).size.width * 1,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),


                  child: Image.network(
                    article.urlToImage,
                    fit: BoxFit.cover,
                  ),
                ),


              SizedBox(height:  MediaQuery.of(context).size.height * 0.02,),
              AutoSizeText(
                  article.title,
                  maxLines: 2,
                  style: TextStyle(fontSize: 14)),
                  SizedBox(height:  MediaQuery.of(context).size.height * 0.01,),
              AutoSizeText(
                "${article.content.substring(0, (article.content.length).floor())}...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}

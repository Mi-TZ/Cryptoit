import 'dart:convert';
import 'package:cryptoo/news/data/news_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_skeleton/flutter_skeleton.dart';
import 'package:provider/provider.dart';

import 'article.dart';
import 'package:cryptoo/news/compents/articleItem.dart';
import 'package:chopper/chopper.dart';

class news extends StatefulWidget {
  @override
  _newsState createState() => _newsState();
}

class _newsState extends State<news> {
  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;

    return SafeArea(
      child: Scaffold(
          backgroundColor: Color(0xFFF2F3F8),
          body: ListView(
            padding: EdgeInsets.all(kDefaultPadding),
            children: <Widget>[

              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  "Crypto News",
                  style: TextStyle(fontSize: 28)
                  ),
              ),

              SizedBox(height: 15,),
              _buildArticle(context, itemWidth, itemHeight)
            ],
          )
      ),
    );

  }

  FutureBuilder<Response> _buildArticle(BuildContext context, double itemWidth, double itemHeight){

    return FutureBuilder<Response>(

      future: Provider.of<NewsApiService>(context).getNews(),

      builder: (context, snapshot){

        if(snapshot.connectionState == ConnectionState.done){

          List<Widget> articles = new List();

          print(snapshot);

          if(snapshot.data != null){

            var  articlesJson = json.decode(snapshot.data.bodyString);

            var articlesMap = articlesJson["articles"];

            for(int i=0; i < articlesMap.length; i++){

              if(articlesMap[i]['urlToImage'] != null && (i%2 != 0)){

                articles.add(ArticleItem(article: Article(
                    name: articlesMap[i]['source']['name'],
                    author: articlesMap[i]['author'],
                    title: articlesMap[i]['title'],
                    description: articlesMap[i]['description'],
                    url: articlesMap[i]['url'],
                    urlToImage: articlesMap[i]['urlToImage'],
                    publishedAt: articlesMap[i]['publishedAt'],
                    content: articlesMap[i]['content']
                ),));

              }

            }

          }

          return  GridView.count(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.all(3),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: (itemWidth / itemHeight) * 006.0,
              crossAxisCount: 1,
              scrollDirection: Axis.vertical,
              children: articles
          );

        }
        else{

          print(snapshot.connectionState);

          return GridView.count(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.all(10),
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
              childAspectRatio: (itemWidth / itemHeight) * 1.9,
              crossAxisCount: 1,
              scrollDirection: Axis.vertical,
              children: [
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),
                CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),CardSkeleton(
                  style: SkeletonStyle(
                    theme: SkeletonTheme.Light,
                    isShowAvatar: false,
                    isCircleAvatar: false,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    barCount: 5,
                    colors: [Colors.grey[100]],
                    backgroundColor: Color(0xffffffff),
                    isAnimation: false,
                  ),
                ),

              ]
          );
        }

      },
    );

  }
}

const  kTitleColor = Color(0xFF14110c);
const  kSubTitleColor = Color(0xFF675531);
const  kBgColor1 = Color(0xFFFFdc7c);
const  kBgColor2 = Color(0xFFddcca1);

const kDefaultPadding = 20.0;
const kDefaultTextSize = 13.0;


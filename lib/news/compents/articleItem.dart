import 'package:flutter/material.dart';

import 'package:cryptoo/news/newsmain.dart';
import 'package:cryptoo/news/detail.dart';
import 'package:cryptoo/news/article.dart';

class ArticleItem extends StatelessWidget {
  final Article article;

  const ArticleItem({
    Key key,
    this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        splashColor: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailScreen(
                        article: article,
                      )));
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 150,
                      height: 90,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.network(
                        article.urlToImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        height: 2,
                      ),
                      Text(article.title, style: TextStyle(fontSize: 14)),
                      SizedBox(
                        height: 2,
                      ),
                      Container(
                        child: Text(
                          "${article.content.substring(0, (article.title.length/2).floor())}...",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

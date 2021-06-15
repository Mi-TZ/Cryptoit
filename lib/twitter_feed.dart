import 'twitter_api_service.dart';
import 'package:flutter/material.dart';
import 'package:tweet_ui/models/api/tweet.dart';
import 'package:tweet_ui/tweet_ui.dart';

class TwitterFeedView extends StatefulWidget {
  const TwitterFeedView({Key key, @required this.hashtag}) : super(key: key);
  final String hashtag;

  @override
  _TwitterFeedViewState createState() => _TwitterFeedViewState();
}

class _TwitterFeedViewState extends State<TwitterFeedView> {
  List tweetsJson = [];
  String errorMessage = '';

  @override
  void initState() {
    getTweets();
    super.initState();
  }

  // Get tweets from Twitter Service
  Future getTweets() async {
    final twitterService = TwitterAPIService(queryTag: widget.hashtag);

    try {
      final List response = await twitterService.getTweetsQuery();

      setState(() {
        tweetsJson = response;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Error retrieving tweets, please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: new AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          backgroundColor: Color(0xFFe7eff9),
          elevation: 0.001,
          centerTitle: true,
          title: Text(
            "#${widget.hashtag}",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 25,
            ),
          ),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: new BoxDecoration(
          gradient: new LinearGradient(
            colors: [
              const Color(0xFFFAFAFA),
              const Color(0xFFe7eff9),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => getTweets(),
          child: tweetsJson.isEmpty
              ? errorMessage.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Center(
                      child: Text(errorMessage),
                    )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  itemCount: tweetsJson.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: EmbeddedTweetView.fromTweet(
                        Tweet.fromJson(tweetsJson[index]),
                        darkMode: false,
                        backgroundColor: Color(0xFFe7eff9).withOpacity(0.5),
                        useVideoPlayer: false,

                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

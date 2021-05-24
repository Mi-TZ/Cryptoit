import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:cryptoo/news/newsmain.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'marketpage.dart';
import 'news/data/news_api_service.dart';
import 'tags.dart';
import 'settings_page.dart';
import 'addcrypto.dart';
import 'package:cryptoo/news/newsmain.dart';

const double appBarHeight = 48.0;
const double appBarElevation = 1.0;

bool shortenOn = false;

List marketListData;
Map portfolioMap;
List portfolioDisplay;
Map totalPortfolioStats;

bool isIOS;
String upArrow = "⬆";
String downArrow = "⬇";

int lastUpdate;
Future<Null> getMarketData() async {
  int pages = 5;
  List tempMarketListData = [];

  Future<Null> _pullData(page) async {
    var response = await http.get(
        Uri.encodeFull(
            "https://min-api.cryptocompare.com/data/top/mktcapfull?tsym=USD&limit=100" +
                "&page=" +
                page.toString()),
        headers: {"Accept": "application/json"});

    List rawMarketListData = new JsonDecoder().convert(response.body)["Data"];
    tempMarketListData.addAll(rawMarketListData);
  }

  List<Future> futures = [];
  for (int i = 0; i < pages; i++) {
    futures.add(_pullData(i));
  }
  await Future.wait(futures);

  marketListData = [];
  // Filter out lack of financial data
  for (Map coin in tempMarketListData) {
    if (coin.containsKey("RAW") && coin.containsKey("CoinInfo")) {
      marketListData.add(coin);
    }
  }

  getApplicationDocumentsDirectory().then((Directory directory) async {
    File jsonFile = new File(directory.path + "/marketData.json");
    jsonFile.writeAsStringSync(json.encode(marketListData));
  });
  print("Got new market data.");

  lastUpdate = DateTime.now().millisecondsSinceEpoch;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await getApplicationDocumentsDirectory().then((Directory directory) async {
    File jsonFile = new File(directory.path + "/portfolio.json");
    if (jsonFile.existsSync()) {
      portfolioMap = json.decode(jsonFile.readAsStringSync());
    } else {
      jsonFile.createSync();
      jsonFile.writeAsStringSync("{}");
      portfolioMap = {};
    }
    if (portfolioMap == null) {
      portfolioMap = {};
    }
    jsonFile = new File(directory.path + "/marketData.json");
    if (jsonFile.existsSync()) {
      marketListData = json.decode(jsonFile.readAsStringSync());
    } else {
      jsonFile.createSync();
      jsonFile.writeAsStringSync("[]");
      marketListData = [];
      // getMarketData(); ?does this work?
    }
  });

  String themeMode = "Automatic";
  bool darkOLED = false;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("shortenOn") != null &&
      prefs.getString("themeMode") != null) {
    shortenOn = prefs.getBool("shortenOn");
    themeMode = prefs.getString("themeMode");
    darkOLED = prefs.getBool("darkOLED");
  }

  runApp(new TraceApp());
}
handleUpdate() {

}
numCommaParse(numString) {
  if (shortenOn) {
    String str = num.parse(numString ?? "0")
        .round()
        .toString()
        .replaceAllMapped(new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => "${m[1]},");
    List<String> strList = str.split(",");

    if (strList.length > 3) {
      return strList[0] +
          "." +
          strList[1].substring(0, 4 - strList[0].length) +
          "B";
    } else if (strList.length > 2) {
      return strList[0] +
          "." +
          strList[1].substring(0, 4 - strList[0].length) +
          "M";
    } else {
      return num.parse(numString ?? "0").toString().replaceAllMapped(
          new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
    }
  }

  return num.parse(numString ?? "0").toString().replaceAllMapped(
      new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
}

normalizeNum(num input) {
  if (input == null) {
    input = 0;
  }
  if (input >= 100000) {
    return numCommaParse(input.round().toString());
  } else if (input >= 1000) {
    return numCommaParse(input.toStringAsFixed(2));
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

normalizeNumNoCommas(num input) {
  if (input == null) {
    input = 0;
  }
  if (input >= 1000) {
    return input.toStringAsFixed(2);
  } else {
    return input.toStringAsFixed(6 - input.round().toString().length);
  }
}

class TraceApp extends StatefulWidget {
  TraceApp();

  @override
  TraceAppState createState() => new TraceAppState();
}

class TraceAppState extends State<TraceApp> {
  void savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setBool("shortenOn", shortenOn);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF2F3F8),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.grey,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return Provider(
      create: (_) => NewsApiService.create(),
      dispose: (_, NewsApiService service) => service.client.dispose(),
      child: new MaterialApp(
        title: "Trace",
        home: BottomNavBar(),
        theme: ThemeData(
          fontFamily: 'Jost',
          primaryColor: Color(0xFFF2F3F8),
        ),
        routes: <String, WidgetBuilder>{
          "/settings": (BuildContext context) => new SettingsPage(
                savePreferences: savePreferences,
              ),
        },
      ),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

void savePreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  prefs.setBool("shortenOn", shortenOn);
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;
  PageController _pageController;

  GlobalKey _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: <Widget>[

            Tabs(
              savePreferences: savePreferences,handleUpdate: handleUpdate,
            ),
            marketpage(
              savePreferences: savePreferences,
            ),
            addcryp(),
            news(),
            SettingsPage(
              savePreferences: savePreferences,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 50.0,
        items: <Widget>[
          Icon(Icons.home_rounded, color: Color(0xFF415860), size: 30),
          Icon(Icons.monetization_on_rounded,
              color: Color(0xFF415860), size: 30),
          Icon(Icons.add_circle_rounded, color: Color(0xFF415860), size: 30),
          Icon(Icons.settings, color: Color(0xFF415860), size: 30),
          Icon(Icons.article_rounded, color: Color(0xFF415860), size: 30),
        ],
        color: Color(0xFFFBFDFA),
        buttonBackgroundColor: Colors.white,
        backgroundColor: Color(0xFFF2F3F8),
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}

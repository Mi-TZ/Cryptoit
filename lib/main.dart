import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:after_layout/after_layout.dart';
import 'package:cryptoo/portfolio/transaction_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:introduction_screen/introduction_screen.dart';
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

const double appBarHeight = 48.0;
const double appBarElevation = 1.0;

bool shortenOn = false;

List marketListData;
Map portfolioMap;
List portfolioDisplay;
Map totalPortfolioStats;
int initScreen;
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

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

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




    runApp(TraceApp());
  }


handleUpdate() {}
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
  bool isFirstTimeOpen = true;

  @override
  TraceAppState createState() => new TraceAppState();
}

class TraceAppState extends State<TraceApp>  with SingleTickerProviderStateMixin {
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
      statusBarColor: Color(0xFFe7eff9).withOpacity(0.7),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Color(0xFFe7eff9),
      systemNavigationBarDividerColor: Color(0xFFe7eff9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return Provider(
      create: (_) => NewsApiService.create(),
      dispose: (_, NewsApiService service) => service.client.dispose(),
      child: new MaterialApp(
        title: "Trace",
        home:new Splash(),
        theme: ThemeData(
          fontFamily: 'Jost',
        ),

      ),
    );
  }
}

class Splash extends StatefulWidget {
  @override
  SplashState createState() => new SplashState();
}

class SplashState extends State<Splash> with AfterLayoutMixin <Splash> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacement(
          new MaterialPageRoute(builder: (context) => new MyHomePage()));
    } else {
      await prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(
          new MaterialPageRoute(builder: (context) => new OnBoardingPage()));
    }
  }

  @override
  void afterFirstLayout(BuildContext context) => checkFirstSeen();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Text('Loading...'),
      ),
    );
  }
}


class OnBoardingPage extends StatefulWidget {
  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> with SingleTickerProviderStateMixin {
  final introKey = GlobalKey<IntroductionScreenState>();
  var initialPage = 0;


  void _onIntroEnd(context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyHomePage()),
    );
  }

  Widget _buildFullscrenImage() {
    return Image.asset(
      'assets/fullscreen.jpg',
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
    );
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    const pageDecoration = const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      globalHeader: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 26, right: 16),
            child: _buildImage('flutter.png', 80),
          ),
        ),
      ),
      globalFooter: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),),
          child: const Text(
            'Let\s go right away!',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _onIntroEnd(context),
        ),
      ),
      pages: [
        PageViewModel(
          title: "Learn , Trade & Practice",
          body:
           "Buy as much Coins you want and HODL them to Check Your Profit & Grow Your Portfolio",
          image: _buildImage('1.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Get Detailed Info",
          body:
          "Get Realtime Info For 500+ Cryptocurrencies & Trade Them!",
          image: _buildImage('2.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Crypto Trainer & Simulator",
          body:
          "Instead Of Risking Your Money, First Learn Basics Through Cryptoit",
          image: _buildImage('3.png'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      //onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      //rtl: true, // Display as right-to-left
      skip: const Text('Skip'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.black54,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<MyHomePage> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    Timer(
        Duration(seconds: 2),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => BottomNavBar())));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            gradient: new LinearGradient(
              colors: [
                const Color(0xFFFAFAFA),
                const Color(0xFFe7eff9),
              ],
            ),
            image: DecorationImage(
              scale: 3.5,
              image: AssetImage('assets/group.png'),
            )));
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
  ScrollController c;
  int _currentIndex = 0;
  PageController _pageController;

  GlobalKey _bottomNavigationKey = GlobalKey();

  Function get loadPortfolio => null;

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
          physics: new NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: <Widget>[
            Tabs(
              savePreferences: savePreferences,
              handleUpdate: handleUpdate,
            ),
            marketpage(
              savePreferences: savePreferences,
            ),
            TransactionSheet(loadPortfolio, marketListData),
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
          Icon(Icons.article_rounded, color: Color(0xFF415860), size: 30),
          Icon(Icons.settings, color: Color(0xFF415860), size: 30),
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

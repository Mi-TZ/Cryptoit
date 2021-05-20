import 'package:cryptoo/portfolio/transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cryptoo/candlesticks.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import '../ballance.dart';

import '../main.dart';
import 'change_bar.dart';

import 'package:cryptoo/portfolio/transition.dart';

import 'exchange_list.dart';

class CoinDetails extends StatefulWidget {
  CoinDetails({
    this.snapshot,
    this.enableTransactions = false,
  });

  final bool enableTransactions;
  final snapshot;

  @override
  CoinDetailsState createState() => new CoinDetailsState();
}

class CoinDetailsState extends State<CoinDetails>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  int _tabAmt;
  List<Widget> _tabBarChildren;
  String symbol;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  _makeTabs() {
    if (widget.enableTransactions) {
      _tabAmt = 3;
      _tabBarChildren = [
        new Tab(text: "Stats"),
        new Tab(text: "Markets"),
        new Tab(text: "Transactions")
      ];
    } else {
      _tabAmt = 2;
      _tabBarChildren = [
        new Tab(text: "Aggregate Stats"),
        new Tab(text: "Markets")
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _makeTabs();
    _tabController = new TabController(length: _tabAmt, vsync: this);

    symbol = widget.snapshot["CoinInfo"]["Name"];

    _makeGeneralStats();
    if (historyOHLCV == null) {
      changeHistory(historyType, historyAmt, historyTotal, historyAgg);
    }
    if (exchangeData == null) {
      _getExchangeData();
    }

    _refreshTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: new Scaffold(
          backgroundColor: Color(0xFFF2F3F8),
          appBar: new PreferredSize(
            preferredSize: const Size.fromHeight(110.0),


            child: new AppBar(
              iconTheme: IconThemeData(
                color: Colors.black, //change your color here
              ),
              backgroundColor: Color(0xFFF2F3F8),
              elevation: 0.001,
              centerTitle: true,
              title: Text(
                'Cryptoit',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 25,
                ),
              ),

              bottom: new PreferredSize(
                preferredSize: const Size.fromHeight(5.0),
                child: new Container(
                    height: 43.0,
                    child: new TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.black54,
                      indicatorWeight: 0.1,
                      unselectedLabelColor: Colors.black54,
                      labelColor: Colors.black54,
                      tabs: _tabBarChildren,
                    )),
              ),
              actions: <Widget>[
                widget.enableTransactions
                    ? new IconButton(
                        icon: new Icon(Icons.add),
                        onPressed: () {
                          _scaffoldKey.currentState
                              .showBottomSheet((BuildContext context) {
                            return new TransactionSheet(() {
                              setState(() {
                                _refreshTransactions();
                              });
                            }, marketListData);
                          });
                        })
                    : new Container(),
              ],
            ),
          ),
          body: new TabBarView(
              controller: _tabController,
              children: widget.enableTransactions
                  ? [
                      aggregateStats(context),
                      exchangeListPage(context),
                      transactionPage(context)
                    ]
                  : [aggregateStats(context), exchangeListPage(context)])),
    );
  }

  Map generalStats;
  List historyOHLCV;

  String _high = "0";
  String _low = "0";
  String _change = "0";

  int currentOHLCVWidthSetting = 0;
  String historyAmt = "720";
  String historyType = "minute";
  String historyTotal = "24h";
  String historyAgg = "2";

  _getGeneralStats() async {
    const int fifteenMin = 15 * 60 * 1000;
    if (lastUpdate != null &&
        fifteenMin != null &&
        DateTime.now().millisecondsSinceEpoch - lastUpdate >= fifteenMin) {
      await getMarketData();
    }
    _makeGeneralStats();
  }

  _makeGeneralStats() {
    for (Map coin in marketListData) {
      if (coin["CoinInfo"]["Name"] == symbol) {
        generalStats = coin["RAW"]["USD"];
        break;
      }
    }
  }

  Future<Null> getHistoryOHLCV() async {
    var response = await http.get(
        Uri.encodeFull("https://min-api.cryptocompare.com/data/histo" +
            ohlcvWidthOptions[historyTotal][currentOHLCVWidthSetting][3] +
            "?fsym=" +
            symbol +
            "&tsym=USD&limit=" +
            (ohlcvWidthOptions[historyTotal][currentOHLCVWidthSetting][1] - 1)
                .toString() +
            "&aggregate=" +
            ohlcvWidthOptions[historyTotal][currentOHLCVWidthSetting][2]
                .toString()),
        headers: {"Accept": "application/json"});
    setState(() {
      historyOHLCV = new JsonDecoder().convert(response.body)["Data"];
      if (historyOHLCV == null) {
        historyOHLCV = [];
      }
    });
  }

  Future<Null> changeOHLCVWidth(int currentSetting) async {
    currentOHLCVWidthSetting = currentSetting;
    historyOHLCV = null;
    getHistoryOHLCV();
  }

  _getHL() {
    num highReturn = -double.infinity;
    num lowReturn = double.infinity;

    for (var i in historyOHLCV) {
      if (i["high"] > highReturn) {
        highReturn = i["high"].toDouble();
      }
      if (i["low"] < lowReturn) {
        lowReturn = i["low"].toDouble();
      }
    }

    _high = normalizeNumNoCommas(highReturn);
    _low = normalizeNumNoCommas(lowReturn);

    var start = historyOHLCV[0]["open"] == 0 ? 1 : historyOHLCV[0]["open"];
    var end = historyOHLCV.last["close"];
    var changePercent = (end - start) / start * 100;
    _change = changePercent.toStringAsFixed(2);
  }

  Future<Null> changeHistory(
      String type, String amt, String total, String agg) async {
    setState(() {
      _high = "0";
      _low = "0";
      _change = "0";

      historyAmt = amt;
      historyType = type;
      historyTotal = total;
      historyAgg = agg;

      historyOHLCV = null;
    });
    _getGeneralStats();
    await getHistoryOHLCV();
    _getHL();
  }

  Widget aggregateStats(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color(0xFFF2F3F8),
      body: new Container(
          child: new Column(
        children: <Widget>[
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    RotatedBox(
                      quarterTurns: 1,
                      child: Container(
                        width: ((160 / 1.2)),
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            HexColor('#009ffd'),
                            HexColor('#2a2a72').withOpacity(0.5),
                          ]),
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 0),
                            child: Text(
                              widget.snapshot["CoinInfo"]["FullName"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 30,
                                letterSpacing: -0.1,
                                color: FitnessAppTheme.grey.withOpacity(0.8),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              SizedBox(
                                width: 1,
                                height: 35,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, bottom: 3),
                                child: Text(
                                  "\$" +
                                      (generalStats != null
                                          ? normalizeNumNoCommas(
                                              generalStats["PRICE"])
                                          : "0"),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 27,
                                    color: FitnessAppTheme.darkerText,
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.3),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                    color: num.parse(_change) >= 0
                                        ? Colors.green
                                        : Colors.redAccent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30))),
                                child: Text(
                                    num.parse(_change) > 0
                                        ? "+" + _change + "%"
                                        : _change + "%",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .body2
                                        .apply(
                                            color: num.parse(_change) >= 0
                                                ? Colors.white
                                                : Colors.white)),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                              MediaQuery.of(context).size.height * 0.004),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 9.0),
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    new Text("Market Cap",
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .apply(
                                                color: Theme.of(context)
                                                    .hintColor)),
                                    new Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0)),
                                    new Text("24h Volume",
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .apply(
                                                color: Theme.of(context)
                                                    .hintColor)),
                                  ],
                                ),
                              ),
                              new Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0)),
                              new Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  new Text(
                                      generalStats != null
                                          ? "\$" +
                                              normalizeNum(
                                                  generalStats["MKTCAP"])
                                          : "0",
                                      style: Theme.of(context)
                                          .textTheme
                                          .body2
                                          .apply(
                                              fontSizeFactor: 1,
                                              fontWeightDelta: 1)),
                                  new Text(
                                      generalStats != null
                                          ? "\$" +
                                              normalizeNum(generalStats[
                                                  "TOTALVOLUME24H"])
                                          : "0",
                                      style: Theme.of(context)
                                          .textTheme
                                          .body2
                                          .apply(
                                              fontSizeFactor: 1,
                                              fontWeightDelta: 1,
                                              color:
                                                  Theme.of(context).hintColor)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.04,
          ),
          new Flexible(
            child: historyOHLCV != null
                ? new Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                        boxShadow: [
                          //background color of box
                          BoxShadow(
                            color: Colors.blueGrey[100].withOpacity(0.5),
                            blurRadius: 40.0, // soften the shadow
                            spreadRadius: 8.010, //extend the shadow
                            offset: Offset(
                              3.0, // Move to right 10  horizontally
                              3.0, // Move to bottom 10 Vertically
                            ),
                          )
                        ],
    gradient: new LinearGradient(
    colors: [
    const Color(0xFFFAFAFA),
    const Color(0xFFe7eff9),
    ],
    ),


                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(60),
                            topRight: Radius.circular(60))),
                    padding: const EdgeInsets.only(
                        left: 22.0, right: 35.0, top: 30.0, bottom: 0),
                    child: new Column(
                      children: <Widget>[
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Row(
                                  children: <Widget>[
                                    new Text("Period",
                                        style: Theme.of(context)
                                            .textTheme
                                            .body1
                                            .apply(
                                                color: Theme.of(context)
                                                    .hintColor)),
                                    new Padding(
                                        padding:
                                            const EdgeInsets.only(right: 3.0)),
                                    new Text(historyTotal,
                                        style: Theme.of(context)
                                            .textTheme
                                            .body2
                                            .apply(fontWeightDelta: 2)),
                                    new Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0)),
                                  ],
                                ),
                                new Row(
                                  children: <Widget>[
                                    new Text("Candle Width",
                                        style: Theme.of(context)
                                            .textTheme
                                            .body1
                                            .apply(
                                                color: Theme.of(context)
                                                    .hintColor)),
                                    new Padding(
                                        padding:
                                            const EdgeInsets.only(right: 2.0)),
                                    new Text(
                                        ohlcvWidthOptions[historyTotal]
                                            [currentOHLCVWidthSetting][0],
                                        style: Theme.of(context)
                                            .textTheme
                                            .body2
                                            .apply(fontWeightDelta: 2))
                                  ],
                                ),
                              ],
                            ),
                            historyOHLCV != null
                                ? new Row(
                                    children: <Widget>[
                                      new Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          new Text("High",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body1
                                                  .apply(
                                                      color: Theme.of(context)
                                                          .hintColor)),
                                          new Text("Low",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body1
                                                  .apply(
                                                      color: Theme.of(context)
                                                          .hintColor)),
                                        ],
                                      ),
                                      new Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 1.5)),
                                      new Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          new Text("\$" + _high,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2),
                                          new Text("\$" + _low,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2)
                                        ],
                                      ),
                                    ],
                                  )
                                : new Container()
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 0,),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                  child: new PopupMenuButton(
                                tooltip: "Select Width",
                                icon: new Icon(Icons.swap_horiz_rounded,
                                    color: Colors.purpleAccent),
                                itemBuilder: (BuildContext context) {
                                  List<PopupMenuEntry<dynamic>> options = [];
                                  for (int i = 0;
                                      i < ohlcvWidthOptions[historyTotal].length;
                                      i++) {
                                    options.add(new PopupMenuItem(
                                        child: new Text(
                                            ohlcvWidthOptions[historyTotal][i]
                                                [0]),
                                        value: i));
                                  }
                                  return options;
                                },
                                onSelected: (result) {
                                  changeOHLCVWidth(result);
                                },
                              )),
                              new Container(
                                  child: new PopupMenuButton(
                                tooltip: "Select Period",
                                icon: new Icon(Icons.timelapse_rounded,
                                    color: Colors.blueAccent),
                                itemBuilder: (BuildContext context) => [
                                  new PopupMenuItem(
                                      child: new Text("1h"),
                                      value: ["minute", "60", "1h", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("6h"),
                                      value: ["minute", "360", "6h", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("12h"),
                                      value: ["minute", "720", "12h", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("24h"),
                                      value: ["minute", "720", "24h", "2"]),
                                  new PopupMenuItem(
                                      child: new Text("3D"),
                                      value: ["hour", "72", "3D", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("7D"),
                                      value: ["hour", "168", "7D", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("1M"),
                                      value: ["hour", "720", "1M", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("3M"),
                                      value: ["day", "90", "3M", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("6M"),
                                      value: ["day", "180", "6M", "1"]),
                                  new PopupMenuItem(
                                      child: new Text("1Y"),
                                      value: ["day", "365", "1Y", "1"]),
                                ],
                                onSelected: (result) {
                                  changeHistory(
                                      result[0], result[1], result[2], result[3]);
                                },
                              )),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 2.0, right: 5.0, top: 20.0, bottom: 10),
                            child: historyOHLCV.isEmpty != true
                                ? new OHLCVGraph(
                                    data: historyOHLCV,
                                    enableGridLines: true,
                                    gridLineColor:
                                        Theme.of(context).dividerColor,
                                    gridLineLabelColor:
                                        Theme.of(context).hintColor,
                                    gridLineAmount: 4,
                                    volumeProp: 0.2,
                                    lineWidth: 1.0,
                                    decreaseColor: Colors.black54,
                                  )
                                : new Container(
                                    padding: const EdgeInsets.all(30.0),
                                    alignment: Alignment.topCenter,
                                    child: new Text("No OHLCV data found :(",
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption),
                                  ),
                          ),
                        )
                      ],
                    ),
                  )
                : new Container(
                    child: new Center(
                      child: new CircularProgressIndicator(),
                    ),
                  ),
          )
        ],
      )),
      bottomNavigationBar: new BottomAppBar(

        elevation: appBarElevation,
        child: generalStats != null
            ? new QuickPercentChangeBar(snapshot: generalStats)
            : new Container(
                height: 0.0,
              ),
      ),
    );
  }

  final columnProps = [.3, .3, .25];
  List exchangeData;

  Future<Null> _getExchangeData() async {
    var response = await http.get(
        Uri.encodeFull(
            "https://min-api.cryptocompare.com/data/top/exchanges/full?fsym=" +
                symbol +
                "&tsym=USD&limit=1000"),
        headers: {"Accept": "application/json"});

    if (new JsonDecoder().convert(response.body)["Response"] != "Success") {
      setState(() {
        exchangeData = [];
      });
    } else {
      exchangeData =
          new JsonDecoder().convert(response.body)["Data"]["Exchanges"];
      _sortExchangeData();
    }
  }

  List sortType = ["VOLUME24HOURTO", true];
  void _sortExchangeData() {
    List sortedExchangeData = [];
    for (var i in exchangeData) {
      if (i["VOLUME24HOURTO"] > 1000) {
        sortedExchangeData.add(i);
      }
    }

    if (sortType[1]) {
      sortedExchangeData
          .sort((a, b) => b[sortType[0]].compareTo(a[sortType[0]]));
    } else {
      sortedExchangeData
          .sort((a, b) => a[sortType[0]].compareTo(b[sortType[0]]));
    }

    setState(() {
      exchangeData = sortedExchangeData;
    });
  }

  Widget exchangeListPage(BuildContext context) {
    return exchangeData != null
        ? new RefreshIndicator(
            onRefresh: () => _getExchangeData(),
            child: exchangeData.isEmpty != true
                ? new CustomScrollView(
                    slivers: <Widget>[
                      new SliverList(
                          delegate: new SliverChildListDelegate(<Widget>[
                        new Container(
                          margin: const EdgeInsets.only(left: 6.0, right: 6.0),
                          decoration: new BoxDecoration(
                              border: new Border(
                                  bottom: new BorderSide(
                                      color: Colors.white, width: 1.0))),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new InkWell(
                                onTap: () {
                                  if (sortType[0] == "MARKET") {
                                    sortType[1] = !sortType[1];
                                  } else {
                                    sortType = ["MARKET", false];
                                  }
                                  setState(() {
                                    _sortExchangeData();
                                  });
                                },
                                child: new Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  width: MediaQuery.of(context).size.width *
                                      columnProps[0],
                                  child: sortType[0] == "MARKET"
                                      ? new Text(
                                          sortType[1] == true
                                              ? "Exchange $upArrow"
                                              : "Exchange $downArrow",
                                          style:
                                              Theme.of(context).textTheme.body2)
                                      : new Text(
                                          "Exchange",
                                          style: Theme.of(context)
                                              .textTheme
                                              .body2
                                              .apply(
                                                  color: Theme.of(context)
                                                      .hintColor),
                                        ),
                                ),
                              ),
                              new InkWell(
                                onTap: () {
                                  if (sortType[0] == "VOLUME24HOURTO") {
                                    sortType[1] = !sortType[1];
                                  } else {
                                    sortType = ["VOLUME24HOURTO", true];
                                  }
                                  setState(() {
                                    _sortExchangeData();
                                  });
                                },
                                child: new Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  alignment: Alignment.centerRight,
                                  width: MediaQuery.of(context).size.width *
                                      columnProps[1],
                                  child: sortType[0] == "VOLUME24HOURTO"
                                      ? new Text(
                                          sortType[1] == true
                                              ? "24h Volume $downArrow"
                                              : "24h Volume $upArrow",
                                          style:
                                              Theme.of(context).textTheme.body2)
                                      : new Text("24h Volume",
                                          style: Theme.of(context)
                                              .textTheme
                                              .body2
                                              .apply(
                                                  color: Theme.of(context)
                                                      .hintColor)),
                                ),
                              ),
                              new Container(

                                width: MediaQuery.of(context).size.width *
                                    columnProps[2],
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    new InkWell(
                                      onTap: () {
                                        if (sortType[0] == "PRICE") {
                                          sortType[1] = !sortType[1];
                                        } else {
                                          sortType = ["PRICE", true];
                                        }
                                        setState(() {
                                          _sortExchangeData();
                                        });
                                      },
                                      child: new Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: sortType[0] == "PRICE"
                                            ? new Text(
                                                sortType[1] == true
                                                    ? "Price $downArrow"
                                                    : "Price $upArrow",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .body2)
                                            : new Text("Price",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .body2
                                                    .apply(
                                                        color: Theme.of(context)
                                                            .hintColor)),
                                      ),
                                    ),
                                    new Text("/",
                                        style: Theme.of(context)
                                            .textTheme
                                            .body2
                                            .apply(
                                                color: Theme.of(context)
                                                    .hintColor)),
                                    new InkWell(
                                      onTap: () {
                                        if (sortType[0] == "CHANGEPCT24HOUR") {
                                          sortType[1] = !sortType[1];
                                        } else {
                                          sortType = ["CHANGEPCT24HOUR", true];
                                        }
                                        setState(() {
                                          _sortExchangeData();
                                        });
                                      },
                                      child: new Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: sortType[0] == "CHANGEPCT24HOUR"
                                            ? new Text(
                                                sortType[1]
                                                    ? "24h $downArrow"
                                                    : "24h $upArrow",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .body2)
                                            : new Text("24h",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .body2
                                                    .apply(
                                                        color: Theme.of(context)
                                                            .hintColor)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ])),
                      new SliverList(
                          delegate: new SliverChildBuilderDelegate(
                        (BuildContext context, int index) =>
                            new ExchangeListItem(
                                exchangeData[index], columnProps),
                        childCount:
                            exchangeData == null ? 0 : exchangeData.length,
                      ))
                    ],
                  )
                : new CustomScrollView(
                    slivers: <Widget>[
                      new SliverList(
                          delegate: new SliverChildListDelegate(<Widget>[
                        new Container(
                          padding: const EdgeInsets.all(30.0),
                          alignment: Alignment.topCenter,
                          child: new Text("No exchanges found :(",
                              style: Theme.of(context).textTheme.caption),
                        )
                      ]))
                    ],
                  ))
        : new Container(
            child: new Center(child: new CircularProgressIndicator()),
          );
  }

  num value;
  num cost;
  num holdings;
  num net;
  num netPercent;
  List transactionList;

  _refreshTransactions() {
    _sortTransactions();
    _updateTotals();
  }

  _updateTotals() {
    value = 0;
    cost = 0;
    holdings = 0;
    net = 0;
    netPercent = 0;

    for (Map transaction in transactionList) {
      cost += transaction["quantity"] * transaction["price_usd"];
      value += transaction["quantity"] * generalStats["PRICE"];
      holdings += transaction["quantity"];
    }

    net = value - cost;

    if (cost > 0) {
      netPercent = ((value - cost) / cost) * 100;
    } else {
      netPercent = 0.0;
    }
  }

  _sortTransactions() {
    if (portfolioMap[symbol] == null) {
      transactionList = [];
    } else {
      transactionList = portfolioMap[symbol];
      transactionList
          .sort((a, b) => (b["time_epoch"].compareTo(a["time_epoch"])));
    }
  }

  Widget transactionPage(BuildContext context) {
    return new CustomScrollView(
      slivers: <Widget>[
        new SliverList(
            delegate: new SliverChildListDelegate(<Widget>[
          new Container(
            padding: const EdgeInsets.all(10.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text("Total Value",
                        style: Theme.of(context).textTheme.caption),
                    new Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        new Text("\$" + numCommaParse(value.toStringAsFixed(2)),
                            style: Theme.of(context)
                                .textTheme
                                .body2
                                .apply(fontSizeFactor: 2.2)),
                      ],
                    ),
                  ],
                ),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text("Total Net",
                        style: Theme.of(context).textTheme.caption),
                    Text(
                        num.parse(holdings.toStringAsPrecision(9)).toString() +
                            " " +
                            symbol,
                        style: Theme.of(context)
                            .textTheme
                            .body2
                            .apply(fontSizeFactor: 1.2)),
                  ],
                ),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    new Text("Total Cost",
                        style: Theme.of(context).textTheme.caption),
                    new Text("\$" + numCommaParse(cost.toStringAsFixed(2)),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .body2
                            .apply(fontSizeFactor: 1.5))
                  ],
                ),
              ],
            ),
          ),
        ])),
        new SliverList(
            delegate: new SliverChildBuilderDelegate(
                (context, index) => new TransactionItem(
                      snapshot: transactionList[index],
                      currentPrice: generalStats["PRICE"],
                      symbol: symbol,
                      refreshPage: () {
                        setState(() {
                          _refreshTransactions();
                        });
                      },
                    ),
                childCount: transactionList.length)),
      ],
    );
  }
}

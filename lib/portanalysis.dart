import 'package:cryptoo/market/coin_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_circular_chart_two/flutter_circular_chart_two.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'ballance.dart';
import 'market_coin_item.dart';
import 'sparkline.dart';
import 'dart:math';
import 'main.dart';


class PortfolioTabs extends StatefulWidget {
  PortfolioTabs(this.makePortfolioDisplay);
  final Function makePortfolioDisplay;

  @override
  PortfolioTabsState createState() => new PortfolioTabsState();
}

class PortfolioTabsState extends State<PortfolioTabs>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 2, vsync: this);
    if (timelineData == null) {
      _getTimelineData();
    }
    _makeColorMap();
    _updateBreakdown();
    _sortPortfolioDisplay();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new PreferredSize(
          preferredSize: const Size.fromHeight(95.0),
          child: new AppBar(
            backgroundColor: Color(0xFFe7eff9),
            titleSpacing: 0.0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: appBarElevation,
            title: new Text("Portfolio Analysis",
                style: Theme.of(context).textTheme.title),
            bottom: new PreferredSize(
                preferredSize: const Size.fromHeight(25.0),
                child: new Container(

                    height: 30.0,
                    child: new TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.black54,
                      indicatorWeight: 1.0,
                      unselectedLabelColor: Theme.of(context).disabledColor,
                      labelColor: Colors.black54,
                      tabs: <Widget>[
                        new Tab(
                          text: "Timeline",
                        ),
                        new Tab(text: "Breakdown"),
                      ],
                    ))),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: new LinearGradient(
              colors: [
                const Color(0xFFFAFAFA),
                const Color(0xFFe7eff9),
              ],
            ),
          ),
          child: new TabBarView(
            controller: _tabController,
            children: <Widget>[_breakdown(context),_timeline(context), ],
          ),
        ));
  }

  final GlobalKey<AnimatedCircularChartState> _chartKey =
  new GlobalKey<AnimatedCircularChartState>();

  num value = 0;
  List<double> timelineData;
  num high = 0;
  num low = 0;
  num changePercent = 0;
  num changeAmt = 0;
  String periodSetting = "24h";

  final Map periodOptions = {
    "24h": {
      "limit": 96,
      "aggregate_by": 15,
      "hist_type": "minute",
      "unit_in_ms": 900000
    },
    "3D": {
      "limit": 72,
      "aggregate_by": 1,
      "hist_type": "hour",
      "unit_in_ms": 3600000
    },
    "7D": {
      "limit": 86,
      "aggregate_by": 2,
      "hist_type": "hour",
      "unit_in_ms": 3600000 * 2
    },
    "1M": {
      "limit": 90,
      "aggregate_by": 8,
      "hist_type": "hour",
      "unit_in_ms": 3600000 * 8
    },
    "3M": {
      "limit": 90,
      "aggregate_by": 1,
      "hist_type": "day",
      "unit_in_ms": 3600000 * 24
    },
    "6M": {
      "limit": 90,
      "aggregate_by": 2,
      "hist_type": "day",
      "unit_in_ms": 3600000 * 24 * 2
    },
    "1Y": {
      "limit": 73,
      "aggregate_by": 5,
      "hist_type": "day",
      "unit_in_ms": 3600000 * 24 * 5
    },
    "All": {
      "limit": 0,
      "aggregate_by": 1,
      "hist_type": "day",
      "unit_in_ms": 3600000 * 24
    }
  };

  List<Map> transactionList;

  Future<Null> _refresh() async {
    await _getTimelineData();
    widget.makePortfolioDisplay();
    _updateBreakdown();
    _sortPortfolioDisplay();
    if (_tabController.index == 1) {
      _chartKey.currentState.updateData(
          [new CircularStackEntry(segments, rankKey: "Portfolio Breakdown")]);
    }
    setState(() {});
  }

  Map<int, double> timedData;
  DateTime oldestPoint = new DateTime.now();
  List<int> times;
  _getTimelineData() async {
    value = totalPortfolioStats["value_usd"];

    timedData = {};
    List<Future> futures = [];
    times = [];

    portfolioMap.forEach((symbol, transactions) {
      num oldest = double.infinity;
      transactions.forEach((transaction) {
        if (transaction["time_epoch"] < oldest) {
          oldest = transaction["time_epoch"];
        }
      });

      futures.add(_pullData({"symbol": symbol, "oldest": oldest}));
      times.add(oldest);
    });

    await Future.wait(futures);
    _finalizeTimelineData();
  }

  Future<Null> _pullData(coin) async {
    int msAgo = new DateTime.now().millisecondsSinceEpoch - coin["oldest"];
    int limit = periodOptions[periodSetting]["limit"];
    int periodInMs = limit * periodOptions[periodSetting]["unit_in_ms"];

    if (periodSetting == "All") {
      limit = msAgo ~/ periodOptions[periodSetting]["unit_in_ms"];
    } else if (msAgo < periodInMs) {
      limit = limit -
          ((periodInMs - msAgo) ~/ periodOptions[periodSetting]["unit_in_ms"]);
    }

    var response = await http.get(
        Uri.encodeFull("https://min-api.cryptocompare.com/data/histo" +
            periodOptions[periodSetting]["hist_type"].toString() +
            "?fsym=" +
            coin["symbol"] +
            "&tsym=USD&limit=" +
            limit.toString() +
            "&aggregate=" +
            periodOptions[periodSetting]["aggregate_by"].toString()),
        headers: {"Accept": "application/json"});

    List responseData = json.decode(response.body)["Data"];

    responseData.forEach((point) {
      num averagePrice = (point["open"] + point["close"]) / 2;

      portfolioMap[coin["symbol"]].forEach((transaction) {
        if (timedData[point["time"]] == null) {
          timedData[point["time"]] = 0.0;
        }

        if (transaction["time_epoch"] - 900000 < point["time"] * 1000) {
          timedData[point["time"]] +=
              (transaction["quantity"] * averagePrice).toDouble();
        }
      });
    });
  }

  _finalizeTimelineData() {
    int oldestInData = times.reduce(min);
    int oldestInRange = new DateTime.now().millisecondsSinceEpoch -
        periodOptions[periodSetting]["unit_in_ms"] *
            periodOptions[periodSetting]["limit"];

    if (oldestInData > oldestInRange || periodSetting == "All") {
      oldestPoint = new DateTime.fromMillisecondsSinceEpoch(oldestInData);
    } else {
      oldestPoint = new DateTime.fromMillisecondsSinceEpoch(oldestInRange);
    }

    timelineData = [];
    timedData.keys.toList()
      ..sort()
      ..forEach((key) => timelineData.add(timedData[key]));

    high = timelineData.reduce(max);
    low = timelineData.reduce(min);

    num start = timelineData[0] != 0 ? timelineData[0] : 1;
    num end = timelineData.last;
    changePercent = (end - start) / start * 100;
    changeAmt = end - start;

    setState(() {});
  }

  _makeTransactionList() {
    transactionList = [];
    portfolioMap.forEach((symbol, transactions) {
      num currentPrice;
      for (Map coin in marketListData) {
        if (coin["CoinInfo"]["Name"] == symbol) {
          currentPrice = coin["RAW"]["USD"]["PRICE"];
          break;
        }
      }

      transactions.forEach((transaction) => transactionList.add({
        "snapshot": transaction,
        "current_price": currentPrice,
        "symbol": symbol
      }));

    });
  }

  Widget _timeline(BuildContext context) {
    _makeTransactionList();
    return portfolioMap.isNotEmpty
        ? new RefreshIndicator(
      onRefresh: _refresh,
      child: new CustomScrollView(slivers: <Widget>[
        new SliverList(
            delegate: new SliverChildListDelegate(<Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.020),
              new Container(
                  padding: const EdgeInsets.all(10.0),
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RotatedBox(
                          quarterTurns: 1,
                          child: Container(
                            width: ((155 / 1.2)),
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                HexColor('#009ffd'),
                                HexColor('#2a2a72').withOpacity(0.5),
                              ]),
                              borderRadius:
                              BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width*
                                0.035),
                        new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text(
                              "Portfolio Value",
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .apply(fontSizeFactor: 1.8),
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    0.0090),
                            new Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Text(
                                    "\$" +
                                        numCommaParse(
                                            value.toStringAsFixed(2)),
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(fontSizeFactor: 1.7)),
                                new Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3.0)),
                              ],
                            ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    0.0090),
//                          new Padding(padding: const EdgeInsets.symmetric(vertical: 2.5)),
                            timelineData != null
                                ? new Row(
                              children: <Widget>[
                                new Text("High",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption),
                                new Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0)),
                                new Text("\$" + normalizeNum(high),
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(fontSizeFactor: 0.9))
                              ],
                            )
                                : new Container(),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    0.0040),
                            timelineData != null
                                ? new Row(
                              children: <Widget>[
                                new Text("Low",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption),
                                new Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3.0)),
                                new Text("\$" + normalizeNum(low),
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(fontSizeFactor: 0.9))
                              ],
                            )
                                : new Container(),
                          ],
                        ),
                      ])),
              new Container(
                padding:
                const EdgeInsets.only(top: 56.0, left: 24.0, right: 55.0),
                height: MediaQuery.of(context).size.height * .56,
                child: timelineData != null
                    ? new Container(
                    child: timelineData.last != 0.0
                        ? new Sparkline(
                      data: timelineData,
                      lineGradient: new LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.purpleAccent,
                            Colors.blueAccent
                          ]),
                      enableGridLines: true,
                      gridLineColor: Theme.of(context).dividerColor,
                      gridLineLabelColor:
                      Theme.of(context).hintColor,
                      gridLineAmount: 4,
                    )
                        : new Container(
                        alignment: Alignment.center,
                        child: new Text(
                            "Transactions too recent or in the future.",
                            style:
                            Theme.of(context).textTheme.caption)))
                    : new Container(
                    alignment: Alignment.center,
                    child: new CircularProgressIndicator()),
              ),
            ])),
      ]),
    )
        : new Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: new Text("Your portfolio is empty. Add a transaction!",
            style: Theme.of(context).textTheme.caption));
  }

  final columnProps = [.2, .3, .3];
  final List colors = [
    Colors.indigo[400].withOpacity(0.6),
    Colors.blue[400].withOpacity(0.6),
    Colors.teal[400].withOpacity(0.6),
    Colors.green[400].withOpacity(0.6),
    Colors.lime[400].withOpacity(0.6),
    Colors.orange[400].withOpacity(0.6),
    Colors.red[400].withOpacity(0.6),
  ];

  num net;
  num netPercent;
  num cost;
  List<CircularSegmentEntry> segments;
  Map colorMap;

  _updateBreakdown() {
    cost = 0;
    net = 0;
    netPercent = 0;

    portfolioMap.forEach((symbol, transactions) {
      transactions.forEach((transaction) {
        cost += transaction["quantity"] * transaction["price_usd"];
      });
    });

    net = value - cost;

    if (cost > 0) {
      netPercent = ((value - cost) / cost) * 100;
    } else {
      netPercent = 0.0;
    }
  }

  _makeSegments() {
    segments = [];
    sortedPortfolioDisplay.forEach((coin) {
      segments.add(new CircularSegmentEntry(
          coin["total_quantity"] * coin["price_usd"], colorMap[coin["symbol"]],
          rankKey: coin["symbol"]));
    });
  }

  _makeColorMap() {
    colorMap = {};
    int colorIndex = 0;
    portfolioDisplay.forEach((coin) {
      if (colorIndex >= colors.length) {
        colorIndex = 1;
      }
      colorMap[coin["symbol"]] = colors[colorIndex];
      colorIndex += 1;
    });
  }

  List portfolioSortType = ["holdings", true];
  List sortedPortfolioDisplay;
  _sortPortfolioDisplay() {
    sortedPortfolioDisplay = portfolioDisplay;
    if (portfolioSortType[1]) {
      if (portfolioSortType[0] == "holdings") {
        sortedPortfolioDisplay.sort((a, b) =>
            (b["price_usd"] * b["total_quantity"])
                .toDouble()
                .compareTo((a["price_usd"] * a["total_quantity"]).toDouble()));
      } else {
        sortedPortfolioDisplay.sort((a, b) =>
            b[portfolioSortType[0]].compareTo(a[portfolioSortType[0]]));
      }
    } else {
      if (portfolioSortType[0] == "holdings") {
        sortedPortfolioDisplay.sort((a, b) =>
            (a["price_usd"] * a["total_quantity"])
                .toDouble()
                .compareTo((b["price_usd"] * b["total_quantity"]).toDouble()));
      } else {
        sortedPortfolioDisplay.sort((a, b) =>
            a[portfolioSortType[0]].compareTo(b[portfolioSortType[0]]));
      }
    }
    _makeSegments();
  }

  Widget _breakdown(BuildContext context) {
    return portfolioMap.isNotEmpty
        ? new RefreshIndicator(
      onRefresh: _refresh,
      child: new CustomScrollView(
        slivers: <Widget>[
          new SliverList(
              delegate: new SliverChildListDelegate(<Widget>[
                new Container(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 10.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[

                      RotatedBox(
                        quarterTurns: 1,
                        child: Container(
                          width: ((180 / 0.95)),
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
                        padding: const EdgeInsets.only(
                            left: 15.0, right: 10.0, top: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[

                            new Text("Portfolio Value",
                                style: Theme.of(context).textTheme.caption),
                            new Text(
                                "\$" +
                                    numCommaParse(value.toStringAsFixed(2)),
                                style: Theme.of(context)
                                    .textTheme
                                    .body2
                                    .apply(fontSizeFactor: 1.6)),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.019),
                            new Text("Total P/L",
                                style: Theme.of(context).textTheme.caption),
                            new PercentDollarChange(
                              exact: net,
                              percent: netPercent,
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.019),
                            new Text("Total Cost",
                                style: Theme.of(context).textTheme.caption),
                            new Text(
                                "\$" + numCommaParse(cost.toStringAsFixed(2)),
                                style: Theme.of(context)
                                    .textTheme
                                    .body2
                                    .apply(fontSizeFactor: 1.4)),
                          ],
                        ),
                      ),
                      SizedBox( width: MediaQuery.of(context).size.width *0.060),
                      new AnimatedCircularChart(
                        key: _chartKey,
                        size: const Size(200.0, 200.0),
                        initialChartData: <CircularStackEntry>[
                          new CircularStackEntry(segments,
                              rankKey: "Portfolio Breakdown")
                        ],
                        chartType: CircularChartType.Pie,
                        edgeStyle: SegmentEdgeStyle.round,
                        duration: new Duration(milliseconds: 500),
                      ),
                    ],
                  ),
                ),
                SizedBox( height: MediaQuery.of(context).size.height  *0.030),
                new Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          bottom: new BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1.0))),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new InkWell(
                        onTap: () {
                          if (portfolioSortType[0] == "symbol") {
                            portfolioSortType[1] = !portfolioSortType[1];
                          } else {
                            portfolioSortType = ["symbol", false];
                          }
                          setState(() {
                            _sortPortfolioDisplay();
                            _chartKey.currentState.updateData([
                              new CircularStackEntry(segments,
                                  rankKey: "Portfolio Breakdown")
                            ]);
                          });
                        },
                        child: new Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          width: MediaQuery.of(context).size.width *
                              columnProps[0],
                          child: portfolioSortType[0] == "symbol"
                              ? new Text(
                              portfolioSortType[1] == true
                                  ? "Currency ⬆"
                                  : "Currency ⬇",
                              style: Theme.of(context).textTheme.body2)
                              : new Text(
                            "Currency",
                            style: Theme.of(context)
                                .textTheme
                                .body2
                                .apply(
                                color: Theme.of(context).hintColor),
                          ),
                        ),
                      ),
                      new InkWell(
                        onTap: () {
                          if (portfolioSortType[0] == "holdings") {
                            portfolioSortType[1] = !portfolioSortType[1];
                          } else {
                            portfolioSortType = ["holdings", true];
                          }
                          setState(() {
                            _sortPortfolioDisplay();
                            _chartKey.currentState.updateData([
                              new CircularStackEntry(segments,
                                  rankKey: "Portfolio Breakdown")
                            ]);
                          });
                        },
                        child: new Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          width: MediaQuery.of(context).size.width *
                              columnProps[1],
                          child: portfolioSortType[0] == "holdings"
                              ? new Text(
                              portfolioSortType[1] == true
                                  ? "Holdings ⬇"
                                  : "Holdings ⬆",
                              style: Theme.of(context).textTheme.body2)
                              : new Text("Holdings",
                              style: Theme.of(context)
                                  .textTheme
                                  .body2
                                  .apply(
                                  color:
                                  Theme.of(context).hintColor)),
                        ),
                      ),

                      new Container(
                        alignment: Alignment.centerRight,
                        width: MediaQuery.of(context).size.width *
                            columnProps[2],
                        child: new Text("Percent of Total",
                            style: Theme.of(context)
                                .textTheme
                                .body2
                                .apply(color: Theme.of(context).hintColor)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              ])),

          new SliverList(
              delegate: new SliverChildBuilderDelegate(
                      (context, index) => new PortfolioBreakdownItem(
                      snapshot: sortedPortfolioDisplay[index],

                      totalValue: totalPortfolioStats["value_usd"],
                      color: colorMap[sortedPortfolioDisplay[index]
                      ["symbol"]]),
                  childCount: sortedPortfolioDisplay.length)),
        ],
      ),
    )
        : new Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: new Text("Your portfolio is empty. Add a transaction!",
            style: Theme.of(context).textTheme.caption));
  }
}


class PercentDollarChange extends StatelessWidget {
  PercentDollarChange({this.percent, this.exact});
  final num percent;
  final num exact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: new Text.rich(new TextSpan(children: [
        (exact ?? 0) > 0
            ? new TextSpan(
            text: "\$${normalizeNum(exact)}",
            style:  TextStyle(
              color: (exact ?? 0) > 0 ?  Colors.green : Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,))
            : new TextSpan(
            text: "\$${normalizeNum(exact)}",
            style:  TextStyle(
              color:(exact ?? 0) > 0 ?  Colors.green : Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,)),
      ])),
    );
  }
}

class PortfolioBreakdownItem extends StatelessWidget {
  PortfolioBreakdownItem({this.snapshot, this.totalValue, this.color});
  final snapshot;
  final num totalValue;
  final Color color;
  final columnProps = [.2, .3, .3];

  _getImage() {
    if (assetImages.contains(snapshot["symbol"].toLowerCase())) {
      return new Image.asset(
          "assets/images/" + snapshot["symbol"].toLowerCase() + ".png",
          height: 24.0);
    } else {
      return new Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      onTap: () {
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (BuildContext context) =>
            new CoinDetails(snapshot: snapshot, enableTransactions: true)));
      },
      child: new Container(
        decoration: new BoxDecoration(),
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.all(5.0),
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Container(
              width: MediaQuery.of(context).size.width * columnProps[0],
              child: new Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _getImage(),
                  new Padding(padding: const EdgeInsets.only(right: 8.0)),
                  new Text(snapshot["symbol"],
                      style: Theme.of(context).textTheme.body2),
                ],
              ),
            ),
            new Container(
              width: MediaQuery.of(context).size.width * columnProps[2],
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  new Text(
                      "\$" +
                          numCommaParse((snapshot["total_quantity"] *
                              snapshot["price_usd"])
                              .toStringAsFixed(2)),
                      style: Theme.of(context)
                          .textTheme
                          .body2
                          .apply(fontSizeFactor: 1.05)),
                ],
              ),
            ),
            new Container(
                width: MediaQuery.of(context).size.width * columnProps[1],
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    new Text(
                        ((snapshot["total_quantity"] * snapshot["price_usd"])
                            .abs() /
                            totalValue.abs() *
                            100)
                            .toStringAsFixed(2) +
                            "%",
                        style: Theme.of(context).textTheme.body2.apply(
                            color: color,
                            fontSizeFactor: 1.3,
                            fontWeightDelta: 2)),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'adstate.dart';
import 'main.dart';
import 'market_coin_item.dart';

class marketpage extends StatefulWidget {
  marketpage({
    this.savePreferences,
  });

  final Function savePreferences;

  @override
  _marketpageState createState() => _marketpageState();
}

class _marketpageState extends State<marketpage>
    with SingleTickerProviderStateMixin {
  TextEditingController textController = TextEditingController();
  TabController _tabController;
  TextEditingController _textController = new TextEditingController();
  bool isSearching = false;
  String filter;
  int _tabIndex = 0;
  final marketColumnProps = [.32, .35, .28];
  List filteredMarketData;
  Map globalData;
  BannerAd _ad;
  bool isLoaded;

  bool sheetOpen = false;

  @override
  void initState() {
    super.initState();

    _tabController = new TabController(length: 2, vsync: this);
    if (_tabController.animation.value.round() != _tabIndex) {}
    _tabController.animation.addListener(() {});

    _filterMarketData();
    _refreshMarketPage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ScrollController _scrollController = new ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: new Scaffold(
          backgroundColor: Color(0xFFF2F3F8),
          body: marketPage(context),
        ),
      ),
    );
  }

  final PageStorageKey _marketKey = new PageStorageKey("market");

  _handleFilter(value) {
    if (value == null) {
      isSearching = false;
      filter = null;
    } else {
      filter = value;
      isSearching = true;
    }
    _filterMarketData();
    setState(() {});
  }

  Future<Null> getGlobalData() async {
    globalData = null;
  }

  Future<Null> _refreshMarketPage() async {
    await getMarketData();
    await getGlobalData();
    _filterMarketData();
  }

  _startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  _stopSearch() {
    setState(() {
      isSearching = false;
      filter = null;
      _filterMarketData();
    });
  }

  _filterMarketData() {
    print("filtering market data");
    filteredMarketData = marketListData;
    if (filter != "" && filter != null) {
      List tempFilteredMarketData = [];
      filteredMarketData.forEach((item) {
        if (item["CoinInfo"]["Name"]
                .toLowerCase()
                .contains(filter.toLowerCase()) ||
            item["CoinInfo"]["FullName"]
                .toLowerCase()
                .contains(filter.toLowerCase())) {
          tempFilteredMarketData.add(item);
        }
      });
      filteredMarketData = tempFilteredMarketData;
    }
    _sortMarketData();
  }

  List marketSortType = ["MKTCAP", true];

  _sortMarketData() {
    if (filteredMarketData == [] || filteredMarketData == null) {
      return;
    }
    // highest to lowest
    if (marketSortType[1]) {
      if (marketSortType[0] == "MKTCAP" ||
          marketSortType[0] == "TOTALVOLUME24H" ||
          marketSortType[0] == "CHANGEPCT24HOUR") {
        print(filteredMarketData);
        filteredMarketData.sort((a, b) =>
            (b["RAW"]["USD"][marketSortType[0]] ?? 0)
                .compareTo(a["RAW"]["USD"][marketSortType[0]] ?? 0));
        if (marketSortType[0] == "MKTCAP") {
          print("adding ranks to filteredMarketData");
          int i = 1;
          for (Map coin in filteredMarketData) {
            coin["rank"] = i;
            i++;
          }
        }
      } else {
        // Handle sorting by name
        filteredMarketData.sort((a, b) =>
            (b["CoinInfo"][marketSortType[0]] ?? 0)
                .compareTo(a["CoinInfo"][marketSortType[0]] ?? 0));
      }
      // lowest to highest
    } else {
      if (marketSortType[0] == "MKTCAP" ||
          marketSortType[0] == "TOTALVOLUME24H" ||
          marketSortType[0] == "CHANGEPCT24HOUR") {
        filteredMarketData.sort((a, b) =>
            (a["RAW"]["USD"][marketSortType[0]] ?? 0)
                .compareTo(b["RAW"]["USD"][marketSortType[0]] ?? 0));
      } else {
        filteredMarketData.sort((a, b) =>
            (a["CoinInfo"][marketSortType[0]] ?? 0)
                .compareTo(b["CoinInfo"][marketSortType[0]] ?? 0));
      }
    }
  }

  Widget marketPage(BuildContext context) {
    return filteredMarketData != null
        ? new RefreshIndicator(
            key: _marketKey,
            onRefresh: () => _refreshMarketPage(),
            child: Scaffold(
              body: Column(
                children: [
                  Container(
                    decoration: new BoxDecoration(
                      gradient: new LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.topRight,
                        colors: [
                          const Color(0xFFFAFAFA),
                          const Color(0xFFE8EFF9),
                        ],

                      ),

                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 17),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Coins',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 35,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.08),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: new Container(
                            width: MediaQuery.of(context).size.width * 0.52,
                            height:
                            MediaQuery.of(context).size.height * 0.055,
                            padding: const EdgeInsets.only(right: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.all(
                                Radius.circular(18.0),
                              ),
                              boxShadow: [
                                //background color of box
                                BoxShadow(
                                  color:
                                  Colors.blueGrey[100].withOpacity(0.7),
                                  blurRadius: 20.0, // soften the shadow
                                  //extend the shadow

                                )
                              ],
                            ),
                            child: new TextFormField(
                              controller: _textController,
                              autocorrect: false,
                              textCapitalization:
                              TextCapitalization.characters,
                              onChanged: (value) => _handleFilter(value),
                              decoration: new InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search_rounded),
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,

                                contentPadding: EdgeInsets.only(
                                    left: 15, bottom: 11, top: 2, right: 15),
                                labelText: "Search Coin",

                                //fillColor: Colors.green
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    decoration: new BoxDecoration(

                      gradient: new LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFAFAFA),
                          const Color(0xFFe7eff9),
                        ],
                      ),
                    ),
                    child: new CustomScrollView(
                      slivers: <Widget>[
                        new SliverList(
                            delegate: new SliverChildListDelegate(<Widget>[
                          globalData != null && isSearching != true
                              ? new Container(
                                  padding: const EdgeInsets.all(10.0),
                                  child: new Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      new Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          new Text(
                                            "Total Market Cap",
                                            style: Theme.of(context)
                                                .textTheme
                                                .body2
                                                .apply(
                                                    color: Theme.of(context)
                                                        .hintColor),
                                          ),
                                          new Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 1.0)),
                                          new Text("Total 24h Volume",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2
                                                  .apply(
                                                      color: Theme.of(context)
                                                          .hintColor)),
                                        ],
                                      ),
                                      new Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 1.0)),
                                      new Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: <Widget>[
                                          new Text(
                                              "\$" +
                                                  normalizeNum(globalData[
                                                      "total_market_cap"]),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2
                                                  .apply(
                                                      fontSizeFactor: 1.2,
                                                      fontWeightDelta: 2)),
                                          new Text(
                                              "\$" +
                                                  normalizeNum(globalData[
                                                      "total_volume_24h"]),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2
                                                  .apply(
                                                      fontSizeFactor: 1.2,
                                                      fontWeightDelta: 2)),
                                        ],
                                      )
                                    ],
                                  ))
                              : new Container(),

                          SingleChildScrollView(
                            child: new Container(
                              margin: const EdgeInsets.only(left: 16.0, right: 6.0),
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
                                      if (marketSortType[0] == "Name") {
                                        marketSortType[1] = !marketSortType[1];
                                      } else {
                                        marketSortType = ["Name", false];
                                      }
                                      setState(() {
                                        _sortMarketData();
                                      });
                                    },
                                    child: new Container(
                                      alignment: Alignment.center,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                      width: MediaQuery.of(context).size.width *
                                          marketColumnProps[0],
                                      child: marketSortType[0] == "Name"
                                          ? new Text(
                                              marketSortType[1]
                                                  ? "Currency " + upArrow
                                                  : "Currency " + downArrow,
                                              style:
                                                  Theme.of(context).textTheme.body2)
                                          : new Text("Currency",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2
                                                  .apply(
                                                      color: Theme.of(context)
                                                          .hintColor)),
                                    ),
                                  ),
                                  new InkWell(
                                    onTap: () {
                                      if (marketSortType[0] == "CHANGEPCT24HOUR") {
                                        marketSortType[1] = !marketSortType[1];
                                      } else {
                                        marketSortType = ["CHANGEPCT24HOUR", true];
                                      }
                                      setState(() {
                                        _sortMarketData();
                                      });
                                    },
                                    child: new Container(
                                      alignment: Alignment.center,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                      width: MediaQuery.of(context).size.width *
                                          marketColumnProps[2],
                                      child: marketSortType[0] == "CHANGEPCT24HOUR"
                                          ? new Text(
                                              marketSortType[1] == true
                                                  ? "Price/24h " + downArrow
                                                  : "Price/24h " + upArrow,
                                              style:
                                                  Theme.of(context).textTheme.body2)
                                          : new Text("Price/24h",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2
                                                  .apply(
                                                      color: Theme.of(context)
                                                          .hintColor)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.009),
                        ])),
                        filteredMarketData.isEmpty
                            ? new SliverList(
                                delegate: new SliverChildListDelegate(<Widget>[
                                new Container(
                                    padding: const EdgeInsets.all(30.0),
                                    alignment: Alignment.topCenter,
                                    child:  new Text("Switch Bottom Tabs Once",
                                        style: Theme.of(context).textTheme.caption),)
                              ]))
                            : new SliverList(
                                delegate: new SliverChildBuilderDelegate(
                                    (BuildContext context, int index) =>
                                        new CoinListItem(filteredMarketData[index],
                                            marketColumnProps),
                                    childCount: filteredMarketData == null
                                        ? 0
                                        : filteredMarketData.length))
                      ],
                    ),
                  ),
                ],
              ),
            ))
        : new Container(
            child: new Center(child: new CircularProgressIndicator()),
          );
  }
}

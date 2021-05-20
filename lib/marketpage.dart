import 'dart:async';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'bottombar.dart';
import 'main.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
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
  bool isSearching = false;
  String filter;

  bool sheetOpen = false;



  @override
  void initState() {
    super.initState();
    _filterMarketData();
    _refreshMarketPage();
  }

  ScrollController _scrollController = new ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: new Scaffold(
          backgroundColor: Color(0xFFF2F3F8), body: marketPage(context)),
    );
  }
}

final PageStorageKey _marketKey = new PageStorageKey("market");

final marketColumnProps = [.32, .35, .28];
List filteredMarketData;
Map globalData;

bool isSearching = false;
String filter;

bool sheetOpen = false;

_handleFilter(value) {
  if (value == null) {
    isSearching = false;
    filter = null;
  } else {
    filter = value;
    isSearching = true;
  }
  _filterMarketData();
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
      filteredMarketData.sort((a, b) => (b["CoinInfo"][marketSortType[0]] ?? 0)
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
      filteredMarketData.sort((a, b) => (a["CoinInfo"][marketSortType[0]] ?? 0)
          .compareTo(b["CoinInfo"][marketSortType[0]] ?? 0));
    }
  }
}

Widget marketPage(BuildContext context) {
  return filteredMarketData != null
      ? new RefreshIndicator(
          key: _marketKey,
          onRefresh: () => _refreshMarketPage(),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Text("Total Market Cap",
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(
                                            color:
                                                Theme.of(context).hintColor),

                                ),


                                new Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 1.0)),
                                new Text("Total 24h Volume",
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(
                                            color:
                                                Theme.of(context).hintColor)),
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
                                        normalizeNum(
                                            globalData["total_market_cap"]),
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(
                                            fontSizeFactor: 1.2,
                                            fontWeightDelta: 2)),
                                new Text(
                                    "\$" +
                                        normalizeNum(
                                            globalData["total_volume_24h"]),
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
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Coins',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    App(),
                  ],
                ),
                new Container(
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
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          width: MediaQuery.of(context).size.width *
                              marketColumnProps[0],
                          child: marketSortType[0] == "Name"
                              ? new Text(
                                  marketSortType[1]
                                      ? "Currency " + upArrow
                                      : "Currency " + downArrow,
                                  style: Theme.of(context).textTheme.body2)
                              : new Text("Currency",
                                  style: Theme.of(context)
                                      .textTheme
                                      .body2
                                      .apply(
                                          color: Theme.of(context).hintColor)),
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
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          width: MediaQuery.of(context).size.width *
                              marketColumnProps[2],
                          child: marketSortType[0] == "CHANGEPCT24HOUR"
                              ? new Text(
                                  marketSortType[1] == true
                                      ? "Price/24h " + downArrow
                                      : "Price/24h " + upArrow,
                                  style: Theme.of(context).textTheme.body2)
                              : new Text("Price/24h",
                                  style: Theme.of(context)
                                      .textTheme
                                      .body2
                                      .apply(
                                          color: Theme.of(context).hintColor)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.009),
              ])),
              filteredMarketData.isEmpty
                  ? new SliverList(
                      delegate: new SliverChildListDelegate(<Widget>[
                      new Container(
                        padding: const EdgeInsets.all(30.0),
                        alignment: Alignment.topCenter,
                        child: new Text("No results found",
                            style: Theme.of(context).textTheme.caption),
                      )
                    ]))
                  : new SliverList(
                      delegate: new SliverChildBuilderDelegate(
                          (BuildContext context, int index) => new CoinListItem(
                              filteredMarketData[index], marketColumnProps),
                          childCount: filteredMarketData == null
                              ? 0
                              : filteredMarketData.length))
            ],
          ))
      : new Container(
          child: new Center(child: new CircularProgressIndicator()),
        );
}

void setState(Null Function() param0) {}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  TextEditingController textController = TextEditingController();
  bool isSearching = false;
  String filter;

  bool sheetOpen = false;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),

      /// In AnimSearchBar widget, the width, textController, onSuffixTap are required properties.
      /// You have also control over the suffixIcon, prefixIcon, helpText and animationDurationInMilli
      child: AnimSearchBar(
        width: 250,
        rtl: true,
        textController: textController,
        onSuffixTap: _startSearch()
      ),
    );
  }
}

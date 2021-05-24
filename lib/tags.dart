import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'ballance.dart';
import 'card.dart';

import 'marketpage.dart';
import 'portfolio/port_tabs.dart';
import 'main.dart';
import 'portfolio_item.dart';
import 'portfolio/transaction_sheet.dart';
import 'market_coin_item.dart';

class Tabs extends StatefulWidget {
  Tabs({this.savePreferences, this.handleUpdate});

  final Function savePreferences;
  final Function handleUpdate;

  @override
  TabsState createState() => new TabsState();
}

class TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  TextEditingController _textController = new TextEditingController();

  _openTransaction() {
    setState(() {
      sheetOpen = true;
    });
    _scaffoldKey.currentState
        .showBottomSheet((BuildContext context) {
          return new TransactionSheet(
            () {
              setState(() {
                _makePortfolioDisplay();
              });
            },
            marketListData,
          );
        })
        .closed
        .whenComplete(() {
          setState(() {
            sheetOpen = false;
          });
        });
  }

  List filteredMarketData;

  _makePortfolioDisplay() {
    print("making portfolio display");
    Map portfolioTotals = {};
    List neededPriceSymbols = [];

    portfolioMap.forEach((coin, transactions) {
      num quantityTotal = 0;
      transactions.forEach((value) {
        quantityTotal += value["quantity"];
      });
      portfolioTotals[coin] = quantityTotal;
      neededPriceSymbols.add(coin);
    });

    portfolioDisplay = [];
    num totalPortfolioValue = 0;
    marketListData.forEach((coin) {
      String symbol = coin["CoinInfo"]["Name"];
      if (neededPriceSymbols.contains(symbol) && portfolioTotals[symbol] != 0) {
        portfolioDisplay.add({
          "symbol": symbol,
          "price_usd": coin["RAW"]["USD"]["PRICE"],
          "percent_change_24h": coin["RAW"]["USD"]["CHANGEPCT24HOUR"],
          "percent_change_1h": coin["RAW"]["USD"]["CHANGEPCTHOUR"],
          "total_quantity": portfolioTotals[symbol],
          "id": coin["CoinInfo"]["Id"],
          "name": coin["CoinInfo"]["FullName"],
          "CoinInfo": coin["CoinInfo"]
        });
        totalPortfolioValue +=
            (portfolioTotals[symbol] * coin["RAW"]["USD"]["PRICE"]);
      }
    });

    num total24hChange = 0;
    num total1hChange = 0;
    portfolioDisplay.forEach((coin) {
      total24hChange += (coin["percent_change_24h"] *
          ((coin["price_usd"] * coin["total_quantity"]) / totalPortfolioValue));
      total1hChange += (coin["percent_change_1h"] *
          ((coin["price_usd"] * coin["total_quantity"]) / totalPortfolioValue));
    });

    totalPortfolioStats = {
      "value_usd": totalPortfolioValue,
      "percent_change_24h": total24hChange,
      "percent_change_1h": total1hChange
    };

    _sortPortfolioDisplay();
  }

  @override
  void initState() {
    super.initState();
    _makePortfolioDisplay();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ScrollController _scrollController = new ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: new Scaffold(
          backgroundColor: Color(0xFFF2F3F8),
          key: _scaffoldKey,
          body: portfolioPage(context)),
    );
  }

  final portfolioColumnProps = [.25, .35, .3];

  Future<Null> _refreshPortfolioPage() async {
    await getMarketData();
    getGlobalData();
    _makePortfolioDisplay();
    setState(() {});
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
  }

  final PageStorageKey _marketKey = new PageStorageKey("market");
  final PageStorageKey _portfolioKey = new PageStorageKey("portfolio");

  Widget portfolioPage(BuildContext context) {
    return new RefreshIndicator(
        key: _portfolioKey,
        onRefresh: _refreshPortfolioPage,
        child: Scaffold(
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
            child: new CustomScrollView(
              slivers: <Widget>[
                new SliverList(
                    delegate: new SliverChildListDelegate(<Widget>[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
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
                            'Portfolio',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  MediterranesnDietView(),
                  new Container(
                    margin: const EdgeInsets.only(left: 6.0, right: 6.0),
                    decoration: new BoxDecoration(
                        border: new Border(
                            bottom: new BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1.0))),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            });
                          },
                          child: new Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            width: MediaQuery.of(context).size.width *
                                portfolioColumnProps[0],
                            child: portfolioSortType[0] == "symbol"
                                ? new Text(
                                    portfolioSortType[1] == true
                                        ? "Currency " + upArrow
                                        : "Currency " + downArrow,
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
                            });
                          },
                          child: new Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            width: MediaQuery.of(context).size.width *
                                portfolioColumnProps[1],
                            child: portfolioSortType[0] == "holdings"
                                ? new Text(
                                    portfolioSortType[1] == true
                                        ? "Holdings " + downArrow
                                        : "Holdings " + upArrow,
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
                        new InkWell(
                          onTap: () {
                            if (portfolioSortType[0] == "percent_change_24h") {
                              portfolioSortType[1] = !portfolioSortType[1];
                            } else {
                              portfolioSortType = ["percent_change_24h", true];
                            }
                            setState(() {
                              _sortPortfolioDisplay();
                            });
                          },
                          child: new Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            width: MediaQuery.of(context).size.width *
                                portfolioColumnProps[2],
                            child: portfolioSortType[0] == "percent_change_24h"
                                ? new Text(
                                    portfolioSortType[1] == true
                                        ? "Price/24h " + downArrow
                                        : "Price/24h " + upArrow,
                                    style: Theme.of(context).textTheme.body2)
                                : new Text("Price/24h",
                                    style: Theme.of(context)
                                        .textTheme
                                        .body2
                                        .apply(
                                            color:
                                                Theme.of(context).hintColor)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                ])),
                portfolioMap.isNotEmpty
                    ? new SliverList(
                        delegate: new SliverChildBuilderDelegate(
                            (context, index) => new PortfolioListItem(
                                sortedPortfolioDisplay[index],
                                portfolioColumnProps),
                            childCount: sortedPortfolioDisplay != null
                                ? sortedPortfolioDisplay.length
                                : 0))
                    : new SliverFillRemaining(
                        child: new Container(
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: new Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                new Text(
                                    "Your portfolio is empty. Add a transaction!",
                                    style: Theme.of(context).textTheme.caption),
                                new Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0)),
                                new RaisedButton(
                                  onPressed: _openTransaction,
                                  child: new Text("New Transaction",
                                      style: Theme.of(context)
                                          .textTheme
                                          .body2
                                          .apply(
                                              color: Theme.of(context)
                                                  .iconTheme
                                                  .color)),
                                )
                              ],
                            ))),
              ],
            ),
          ),
        ));
  }
}

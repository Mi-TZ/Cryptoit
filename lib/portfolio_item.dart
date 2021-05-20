import 'package:flutter/material.dart';

import 'main.dart';
import 'market/coin_tabs.dart';
import 'market_coin_item.dart';

class PortfolioListItem extends StatelessWidget {
  PortfolioListItem(this.snapshot, this.columnProps);
  final columnProps;
  final Map snapshot;

  _getImage() {
    if (assetImages.contains(snapshot["symbol"].toLowerCase())) {
      return new Image.asset(
          "assets/images/" + snapshot["symbol"].toLowerCase() + ".png",
          height: 28.0);
    } else {
      return new Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new InkWell(
        onTap: () {
          Navigator.of(context).push(new MaterialPageRoute(
              builder: (BuildContext context) => new CoinDetails(
                  snapshot: snapshot, enableTransactions: true)));
        },
        child: new Container(
          margin: new EdgeInsets.all(10.0),
          width: MediaQuery.of(context).size.width * 1,

          decoration: BoxDecoration(
              boxShadow: [ //background color of box
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 50.0, // soften the shadow
                  spreadRadius: 0.0, //extend the shadow
                  offset: Offset(
                    3.0, // Move to right 10  horizontally
                    3.0, // Move to bottom 10 Vertically
                  ),
                )
              ],
              color: Colors.white,

              borderRadius: BorderRadius.all(Radius.circular(15))),
          padding: const EdgeInsets.all( 20),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Container(
                width: MediaQuery.of(context).size.width * columnProps[0],
                child: new Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _getImage(),
                    new Padding(padding: const EdgeInsets.only(right: 9.0)),
                    new Text(snapshot["symbol"],
                        style: Theme.of(context).textTheme.body2),
                  ],
                ),
              ),
              new Container(
                  width: MediaQuery.of(context).size.width * columnProps[1],
                  child: new Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Text(
                          "\$" +
                              numCommaParse((snapshot["total_quantity"] *
                                  snapshot["price_usd"])
                                  .toStringAsFixed(2)),
                          style: Theme.of(context).textTheme.body2),
                      new Padding(padding: const EdgeInsets.only(bottom: 4.0)),
                      new Text(
                          num.parse(snapshot["total_quantity"]
                              .toStringAsPrecision(9))
                              .toString(),
                          style: Theme.of(context)
                              .textTheme
                              .body2
                              .apply(color: Theme.of(context).hintColor))
                    ],
                  )),
              new Container(
                width: MediaQuery.of(context).size.width * columnProps[2],
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                        "\$" + normalizeNumNoCommas(snapshot["price_usd"])),
                    new Padding(padding: const EdgeInsets.only(bottom: 4.0)),
                    new Text(
                        (snapshot["percent_change_24h"] ?? 0) >= 0
                            ? "+" + (snapshot["percent_change_24h"] ?? 0)
                            .toStringAsFixed(2) + "%"
                            : (snapshot["percent_change_24h"] ?? 0)
                            .toStringAsFixed(2) + "%",
                        style: Theme.of(context).primaryTextTheme.body1.apply(
                            color: (snapshot["percent_change_24h"] ?? 0) >= 0
                                ? Colors.green
                                : Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
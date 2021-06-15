import 'package:flutter/material.dart';
import 'transaction_sheet.dart';
import '../main.dart';

class TransactionItem extends StatelessWidget {
  TransactionItem(
      {this.snapshot, this.symbol, this.currentPrice, this.refreshPage});
  final Map snapshot;
  final String symbol;
  final num currentPrice;

  final Function refreshPage;

  @override
  Widget build(BuildContext context) {
    String date;
    final DateTime time =
    new DateTime.fromMillisecondsSinceEpoch(snapshot["time_epoch"]);
    final double changePercent =
        (currentPrice - snapshot["price_usd"]) / snapshot["price_usd"] * 100;

    if (time.minute < 10) {
      date = time.month.toString() +
          "/" +
          time.day.toString() +
          "/" +
          time.year.toString().substring(2) +
          " " +
          time.hour.toString() +
          ":0" +
          time.minute.toString();
    } else {
      date = time.month.toString() +
          "/" +
          time.day.toString() +
          "/" +
          time.year.toString().substring(2) +
          " " +
          time.hour.toString() +
          ":" +
          time.minute.toString();
    }

    String exchange = snapshot["exchange"];
    if (exchange == "CCCAGG") {
      exchange = "Aggregated";
    }

    return new Container(
      margin: new EdgeInsets.all(10.0),
      width: MediaQuery.of(context).size.width * 0.06,
      height: MediaQuery.of(context).size.height * 0.1,
      decoration: BoxDecoration(
          boxShadow: [ //background color of box
            BoxShadow(
              color: Colors.grey[100],
              blurRadius: 50.0, // soften the shadow
              spreadRadius: 0.0, //extend the shadow
              offset: Offset(
                3.0, // Move to right 10  horizontally
                3.0, // Move to bottom 10 Vertically
              ),
            )
          ],
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.all(Radius.circular(15))),
      child: new ListTile(
        isThreeLine: false,
        contentPadding: const EdgeInsets.all(8.0),

        leading: snapshot["quantity"] >= 0
            ? new Icon(Icons.add_circle, color: Colors.green, size: 28.0)
            : new Icon(Icons.remove_circle, color: Colors.red, size: 28.0),
        title: new RichText(
            text: TextSpan(children: <TextSpan>[
              TextSpan(
                  text: "${snapshot["quantity"]} $symbol",
                  style:
                  Theme.of(context).textTheme.body2.apply(fontWeightDelta: 2)),
              TextSpan(text: " at ", style: Theme.of(context).textTheme.body1),
              TextSpan(
                  text:
                  "\$${num.parse(normalizeNumNoCommas(snapshot["price_usd"])).toString()}",
                  style:
                  Theme.of(context).textTheme.body2.apply(fontWeightDelta: 2)),
              TextSpan(
                  text: changePercent > 0
                      ? " +" + changePercent.toStringAsFixed(2) + "%"
                      : " " + changePercent.toStringAsFixed(2) + "%",
                  style: Theme.of(context)
                      .textTheme
                      .body2
                      .apply(color: changePercent > 0 ? Colors.green : Colors.red)),
            ])),
        subtitle: new Text(
            "$exchange (\$${numCommaParse((snapshot["quantity"] * snapshot["price_usd"]).toStringAsFixed(2))})\n$date"),
        trailing: snapshot["notes"] != ""
            ? new Container(
          alignment: Alignment.topRight,
          width: MediaQuery.of(context).size.width * .3,
          child: new Text(snapshot["notes"],
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
              style: Theme.of(context).textTheme.caption),
        )
            : null,
      ),
    );
  }
}

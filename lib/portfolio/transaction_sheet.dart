import 'dart:math';
import 'package:cryptoo/adstate.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:slider_button/slider_button.dart';

import '../main.dart';

class TransactionSheet extends StatefulWidget {
  TransactionSheet(
    this.loadPortfolio,
    this.marketListData, {
    Key key,
    this.editMode: false,
    this.snapshot,
    this.symbol,
  }) : super(key: key);

  final Function loadPortfolio;
  final List marketListData;
  final bool editMode;
  final Map snapshot;
  final String symbol;

  @override
  TransactionSheetState createState() => new TransactionSheetState();
}

class TransactionSheetState extends State<TransactionSheet> {
  InterstitialAd interstitialAd;
  int _toggleValue = 0;
  int value = 0;
  bool positive = false;
  TextEditingController _symbolController = new TextEditingController();
  TextEditingController _priceController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _exchangeController = new TextEditingController();
  TextEditingController _notesController = new TextEditingController();

  FocusNode _priceFocusNode = new FocusNode();
  FocusNode _quantityFocusNode = new FocusNode();
  FocusNode _notesFocusNode = new FocusNode();

  Color errorColor = Colors.red;
  Color validColor;

  int radioValue = 0;
  DateTime pickedDate = new DateTime.now();
  TimeOfDay pickedTime = new TimeOfDay.now();
  int epochDate;

  List symbolList;
  Color symbolTextColor;
  String symbol;

  Color quantityTextColor;
  num quantity;

  Color priceTextColor;
  num price;

  List exchangesList;
  String exchange;

  Map totalQuantities;

  InterstitialAd _interstitialAd;
  bool isLoaded;

  _makeTotalQuantities() {
    totalQuantities = {};
    portfolioMap.forEach((symbol, transactions) {
      num total = 0;
      transactions.forEach((transaction) => total += transaction["quantity"]);
      totalQuantities[symbol] = total;
    });
    if (widget.editMode) {
      totalQuantities[widget.symbol] -= widget.snapshot["quantity"];
    }
  }

  _handleRadioValueChange(int value) {
    radioValue = value;
    _checkValidQuantity(_quantityController.text);
  }

  Future<Null> _selectDate() async {
    DateTime pick = await showDatePicker(
        context: context,
        initialDate: new DateTime.now(),
        firstDate: new DateTime(1950),
        lastDate: new DateTime.now());
    if (pick != null) {
      setState(() {
        pickedDate = pick;
      });
      _makeEpoch();
    }
  }

  Future<Null> _selectTime() async {
    TimeOfDay pick = await showTimePicker(
        context: context, initialTime: new TimeOfDay.now());
    if (pick != null) {
      setState(() {
        pickedTime = pick;
      });
      _makeEpoch();
    }
  }

  _makeEpoch() {
    epochDate = new DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute)
        .millisecondsSinceEpoch;
  }

  _checkValidSymbol(String inputSymbol) async {
    if (symbolList == null || symbolList.isEmpty) {
      symbolList = [];
      widget.marketListData
          .forEach((value) => symbolList.add(value["CoinInfo"]["Name"]));
    }

    if (symbolList.contains(inputSymbol.toUpperCase())) {
      symbol = inputSymbol.toUpperCase();
      exchangesList = null;
      _getExchangeList();

      for (var value in widget.marketListData) {
        if (value["CoinInfo"]["Name"] == symbol) {
          price = value["RAW"]["USD"]["PRICE"];
          _priceController.text = price.toString();
          priceTextColor = validColor;
          break;
        }
      }

      exchange = "CCCAGG";
      _exchangeController.text = "Aggregated";
      symbolTextColor = validColor;
      _checkValidQuantity(_quantityController.text);
    } else {
      symbol = null;
      exchangesList = null;
      exchange = null;
      _exchangeController.text = "";
      price = null;
      _priceController.text = "";
      symbolTextColor = errorColor;
      _checkValidQuantity(_quantityController.text);
    }
  }

  _checkValidQuantity(String quantityString) {
    try {
      quantity = num.parse(quantityString);
      if (quantity <= 0 ||
          radioValue == 1 && totalQuantities[symbol] - quantity < 0) {
        quantity = null;
        setState(() {
          quantityTextColor = errorColor;
        });
      } else {
        setState(() {
          quantityTextColor = validColor;
        });
      }
    } catch (e) {
      quantity = null;
      setState(() {
        quantityTextColor = errorColor;
      });
    }
  }

  _checkValidPrice(String priceString) {
    try {
      price = num.parse(priceString);
      if (price.isNegative) {
        price = null;
        setState(() {
          priceTextColor = errorColor;
        });
      } else {
        setState(() {
          priceTextColor = validColor;
        });
      }
    } catch (e) {
      price = null;
      setState(() {
        priceTextColor = errorColor;
      });
    }
  }

  _handleSave() async {
    if (symbol != null &&
        quantity != null &&
        exchange != null &&
        price != null) {
      print("WRITING TO JSON...");

      await getApplicationDocumentsDirectory().then((Directory directory) {
        File jsonFile = new File(directory.path + "/portfolio.json");
        if (jsonFile.existsSync()) {
          if (radioValue == 1) {
            quantity = -quantity;
          }

          Map newEntry = {
            "quantity": quantity,
            "price_usd": price,
            "exchange": exchange,
            "time_epoch": epochDate,
            "notes": _notesController.text
          };

          Map jsonContent = json.decode(jsonFile.readAsStringSync());
          if (jsonContent == null) {
            jsonContent = {};
          }

          try {
            jsonContent[symbol].add(newEntry);
          } catch (e) {
            jsonContent[symbol] = [];
            jsonContent[symbol].add(newEntry);
          }

          if (widget.editMode) {
            int index = 0;
            for (Map transaction in jsonContent[widget.symbol]) {
              if (transaction.toString() == widget.snapshot.toString()) {
                jsonContent[widget.symbol].removeAt(index);
                break;
              }
              index += 1;
            }
          }

          portfolioMap = jsonContent;
          jsonFile.writeAsStringSync(json.encode(jsonContent));

          Fluttertoast.showToast(
              msg: "Transaction Completed",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0);

          _priceController.clear();
          _quantityController.clear();
          _exchangeController.clear();
          _notesController.clear();
          _symbolController.clear();
        } else {
          jsonFile.createSync();
          jsonFile.writeAsStringSync("{}");
        }
      });
      widget.loadPortfolio();
    }
  }

  Future<Null> _getExchangeList() async {
    var response = await http.get(
        Uri.encodeFull(
            "https://min-api.cryptocompare.com/data/top/exchanges?fsym=" +
                symbol +
                "&tsym=USD&limit=100"),
        headers: {"Accept": "application/json"});

    exchangesList = [];

    List exchangeData = new JsonDecoder().convert(response.body)["Data"];
    exchangeData.forEach((value) => exchangesList.add(value["exchange"]));
  }

  _initEditMode() {
    _symbolController.text = widget.symbol;
    _checkValidSymbol(_symbolController.text);

    _priceController.text = widget.snapshot["price_usd"].toString();
    _checkValidPrice(_priceController.text);

    _quantityController.text = widget.snapshot["quantity"].abs().toString();
    _checkValidQuantity(_quantityController.text);

    if (widget.snapshot["quantity"].isNegative) {
      radioValue = 1;
    }

    if (widget.snapshot["exchange"] == "CCCAGG") {
      _exchangeController.text = "Aggregated";
    } else {
      _exchangeController.text = widget.snapshot["exchange"];
    }
    exchange = widget.snapshot["exchange"];

    _notesController.text = widget.snapshot["notes"];

    pickedDate =
        new DateTime.fromMillisecondsSinceEpoch(widget.snapshot["time_epoch"]);
    pickedTime = new TimeOfDay.fromDateTime(pickedDate);
  }

  @override
  void initState() {
    super.initState();

    symbolTextColor = errorColor;
    quantityTextColor = errorColor;
    priceTextColor = errorColor;

    if (widget.editMode) {
      _initEditMode();
    }
    _makeTotalQuantities();
    _makeEpoch();
  }

  void loadInterstitial() async {
    interstitialAd = InterstitialAd(
      // adUnitId: 'ca-app-pub-9746660700461224/1972272971',
      request: AdRequest(),
      listener: AdListener(onAdLoaded: (Ad ad) {
        interstitialAd.show();
      }, onAdClosed: (Ad ad) {
        interstitialAd.dispose();
      }),
    );

    interstitialAd.load();
  }

  @override
  Widget build(BuildContext context) {
    validColor = Theme.of(context).textTheme.body2.color;
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return new AlertDialog(
                    title: new Text(
                      "How Transaction Works",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    content: new Text(
                      "* Enter Coin Symbol in Field eg : BTC,ETH,DOGE. \n* To Add Coins In Your Portfolio Select Buy. \n* To Delete Coins From Your Portfolio Select Sell. \n* After Swiping The Coin You Entered Will Be Added To Portfolio.",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    actions: <Widget>[
                      new FlatButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: new Text("okay!"))
                    ],
                  );
                },
              );
            },
            label: const Icon(Icons.info_outline_rounded),
            backgroundColor: Colors.blueAccent.withOpacity(0.5),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 38,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Transaction',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.001),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedToggle(
                              values: ['BUY', 'SELL'],
                              onToggleCallback: (value) {
                                setState(() {
                                  _handleRadioValueChange(value);
                                });
                              },
                              buttonColor: Colors.blue.shade400,
                              backgroundColor: const Color(0xFFB5C1CC),
                              textColor: const Color(0xFFFFFFFF),
                            ),
                          ],
                        ),
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.045),
                        new Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          padding: const EdgeInsets.only(right: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.all(
                              Radius.circular(18.0),
                            ),
                            boxShadow: [
                              //background color of box
                              BoxShadow(
                                color: Colors.blueGrey[100].withOpacity(0.7),
                                blurRadius: 40.0, // soften the shadow
                                spreadRadius: 8.010, //extend the shadow
                                offset: Offset(
                                  3.0, // Move to right 10  horizontally
                                  3.0, // Move to bottom 10 Vertically
                                ),
                              )
                            ],
                          ),
                          child: new TextField(
                            controller: _symbolController,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: _checkValidSymbol,
                            onSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_quantityFocusNode),
                            decoration: new InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                  left: 15, bottom: 11, top: 11, right: 15),
                              labelText: "Enter Coin",

                              //fillColor: Colors.green
                            ),
                          ),
                        ),
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.025),
                        new Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          padding: const EdgeInsets.only(right: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.all(
                              Radius.circular(18.0),
                            ),
                            boxShadow: [
                              //background color of box
                              BoxShadow(
                                color: Colors.blueGrey[100].withOpacity(0.7),
                                blurRadius: 40.0, // soften the shadow
                                spreadRadius: 8.010, //extend the shadow
                                offset: Offset(
                                  3.0, // Move to right 10  horizontally
                                  3.0, // Move to bottom 10 Vertically
                                ),
                              )
                            ],
                          ),
                          child: new TextField(
                            focusNode: _quantityFocusNode,
                            controller: _quantityController,
                            autocorrect: false,
                            onChanged: _checkValidQuantity,
                            onSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_priceFocusNode),
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: new InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                    left: 15, bottom: 11, top: 11, right: 15),
                                labelText: "Quantity",
                                fillColor: Colors.black54

                                //fillColor: Colors.green
                                ),
                          ),
                        ),
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.025),
                        new Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          padding: const EdgeInsets.only(right: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.all(
                              Radius.circular(18.0),
                            ),
                            boxShadow: [
                              //background color of box
                              BoxShadow(
                                color: Colors.blueGrey[100].withOpacity(0.7),
                                blurRadius: 40.0, // soften the shadow
                                spreadRadius: 8.010, //extend the shadow
                                offset: Offset(
                                  3.0, // Move to right 10  horizontally
                                  3.0, // Move to bottom 10 Vertically
                                ),
                              )
                            ],
                          ),
                          child: new TextField(
                            focusNode: _priceFocusNode,
                            controller: _priceController,
                            autocorrect: false,
                            onChanged: _checkValidPrice,
                            onSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_notesFocusNode),
                            style: Theme.of(context)
                                .textTheme
                                .body2
                                .apply(color: priceTextColor),
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: new InputDecoration(
                                border: InputBorder.none,
                                prefixText: "\$",
                                prefixStyle: Theme.of(context)
                                    .textTheme
                                    .body2
                                    .apply(color: priceTextColor),
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                    left: 15, bottom: 11, top: 11, right: 15),
                                labelText: "Price",
                                fillColor: Colors.black54

                                //fillColor: Colors.green
                                ),
                          ),
                        ),


                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.045),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                child: SliderButton(
                                  action: () {
                                    loadInterstitial();
                                    _handleSave();
                                  },
                                  label: Text(
                                    "Slide To Confirm",
                                    style: TextStyle(
                                        color: Color(0xff4a4a4a),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 17),
                                  ),
                                  icon: Icon(
                                    Icons.check,
                                    color: Colors.blueAccent,
                                  ),
                                  width: 260,
                                  buttonColor: Color(0xFFFAFAFA),
                                  boxShadow: BoxShadow(
                                    color: Colors.blueGrey[100],
                                    blurRadius: 8,
                                  ),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.7),
                                  baseColor: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.095),
                      ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedToggle extends StatefulWidget {
  final List<String> values;
  final ValueChanged onToggleCallback;
  final Color backgroundColor;
  final Color buttonColor;
  final Color textColor;

  AnimatedToggle({
    @required this.values,
    @required this.onToggleCallback,
    this.backgroundColor = const Color(0xFFe7e7e8),
    this.buttonColor = const Color(0xFFFFFFFF),
    this.textColor = const Color(0xFF000000),
  });
  @override
  _AnimatedToggleState createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<AnimatedToggle> {
  bool initialPosition = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.055,
      margin: EdgeInsets.all(20),
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              initialPosition = !initialPosition;
              var index = 0;
              if (!initialPosition) {
                index = 1;
              }
              widget.onToggleCallback(index);
              setState(() {});
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.13,
              decoration: ShapeDecoration(
                color: widget.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  widget.values.length,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05),
                    child: Text(
                      widget.values[index],
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFe7e7e8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.decelerate,
            alignment:
                initialPosition ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.33,
              height: MediaQuery.of(context).size.height * 0.13,
              decoration: ShapeDecoration(
                color:
                    initialPosition ? Colors.green.shade500 : Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.1),
                ),
              ),
              child: Text(
                initialPosition ? widget.values[0] : widget.values[1],
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }
}

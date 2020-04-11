import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notification.dart';
import 'ble.dart';

void main() => runApp(MyApp());

class ERR {
  //serious
  static const int BLE_NOT_SUPPORTED = -1;
  static const int CANNOT_GET_BLE_ADAPTER = -2;
  static const int BT_NOT_ENABLE = -3;
  static const int NO_BT_SCANNER = -4;

  static const int NO_LOCATION_PERMISSION = -5;
  static const int SERIOUS = -5;
  // not serious
  static const int NO_BT_DEVICE = -6;
  static const int NO_BT_GATT = -7;
  static const int NOT_FOUND_DEVICE = -8;
  static const int NOT_CONNECTED_DEVICE = -9;
  static const int BT_BATCH_SCAN = -10;
  static const int BT_SCAN_FAILED = -11;
  static const int BT_SERVICE_NOT_FOUND = -12;
  static const int BT_CANT_READ = -13;
  static const int BT_CHAR_NOT_FOUND = -14;
  static const int BT_DESCR_NOT_FOUND = -15;
  static const int BT_CANT_NOTIFIED = -16;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
     ]);
    return MaterialApp(
      title: 'Ohvino Demo',
      debugShowCheckedModeBanner: false ,
      theme: ThemeData(
        primarySwatch: Colors.blue,
//        backgroundColor: Colors.grey,
        scaffoldBackgroundColor: Color( 0xFFFDDDDDD), //Colors.grey[50],
      ),
      home: MyHomePage(title: 'OhVino - сделай вино вкуснее!'), //tastier
    );
  }
}

class VinoBox {
  int _packetCouner = 0;
  int _winTemp = 0;
  int _batt = 0;
  int _extTemp = -100;
  int _rSSI = 0;
  int _error = 0;

  int getPacketCounter() { return _packetCouner;}
  int getWinTemp() { return  _winTemp;}
  int getBatt() { return _batt;}
  int getExtTemp() { return _extTemp;}
  int getRSSI() { return _rSSI;}
  int getError() { return _error;}

  static const int _ERROR = -1000;

  int _converter( String subSrt) {
    int tmp = int.tryParse(subSrt) ?? _ERROR;
    if (tmp == _ERROR) {
      _error = _ERROR;
      return _error;
    }
    return tmp;
  }

  bool isError() { return _error < 0;}

  void setData( String str) {
    _error = 0;
    if(str.length != 18) {
      _error = _ERROR;
      return;
    }
    if( str.contains("Error")) {
      _error = _converter( str.substring( str.indexOf(":")+1));
      return;
    }
    int i = 0;
    _packetCouner = _converter( str.substring( i, i+4));
    i += 4;
    _winTemp = _converter( str.substring( i, i+3));
    i += 3;
    _batt = _converter( str.substring( i, i+3));
    i += 3;
    _extTemp = _converter( str.substring( i, i+4));
    i += 4;
    _rSSI = _converter( str.substring( i));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class PresetTempButton extends Visibility {
  PresetTempButton( String txt, Color colorBack, Color colorTxt, double this._temperature, this._func, bool vision) : super (
    child: Padding(
        padding: EdgeInsets.all(_padPreset),
        child: RaisedButton(
          padding: EdgeInsets.all(_edgePreset),
          shape: new RoundedRectangleBorder( side: new BorderSide(width: 1.0, color: Colors.black),
              borderRadius: new BorderRadius.circular(20.0)),
          color: colorBack,
          textColor: colorTxt,
          child: Text( txt,
            style: TextStyle(
                fontSize: _fontPreset,
                fontWeight: FontWeight.bold,
                textBaseline: TextBaseline.alphabetic
            ),
          ),
          onPressed: () => _func( _temperature),
        )
    ),
    visible: vision,
  );
  static const double _edgePreset = 20.0;
  static const double _padPreset = 15.0;
  static const double _fontPreset = 20.0;

  MyHomePageState _parent;
  double _temperature;
  Function(double tempearture) _func;
}

class PlusMinusButton extends Padding {
  PlusMinusButton( String txt, this._func) : super (
    padding: EdgeInsets.all(_edgePlus),
    child: RaisedButton(
      padding: EdgeInsets.all(_edgePlus),
      shape: new RoundedRectangleBorder( side: new BorderSide(width: 3.0, color: Colors.black),
          borderRadius: new BorderRadius.circular(30.0)),
      color: Colors.blue,
      textColor: Colors.white,
        child: Text( txt,
          style: TextStyle(
          fontSize: _fontPlus,
          fontWeight: FontWeight.bold,
          textBaseline: TextBaseline.alphabetic
          ),
        ),
      onPressed: _func,
    )
  );

  static const double _edgePlus = 15.0;
  static const double _fontPlus = 40.0;

  Function() _func;
}



class MyHomePageState extends State<MyHomePage> {

  int _initTimeLimit = 21;

  MyHomePageState() {
    _bleDevice = BleDevice( this, _initTimeLimit);
  }

  MyNotification _notification = MyNotification();

  BleDevice _bleDevice;

  void _setMessage( String str) {
    setState(() {
      _msg = str;
    });
  }

  void bleInitError( int result) {
      _setMessage('BLE init error ' + '$result');
      _floatPressed();
   }

  void bleLimitSetError( ) {
    _setMessage('BLE limit set error ');
//    _floatPressed();
  }

  void bleInitSuccess() {
     _initProgressBegin();
   }

  void bleInitFlutterError( String resultStr) {
    _setMessage('bleInitFlutterError '+ resultStr);
  }

  void bleConnectError( int error) {
    _initProgressStop();
    _setMessage('bleConnectError $error');
    _floatPressed();
  }

  void bleIsConnected() {
    _initProgressStop();
    _setMessage('Ждём-с...'); //
  }

  void bleCheckFlutterError( String error) {
    _setMessage('bleCheckFlutterError '+ error);
  }

  void bleCheckDisconnectedSuddenly() {
  }

  void bleCheckSomeError( int result) {
  }

  void bleCheckSuccess( VinoBox vinoBox) {
   _fillFromVineBox( vinoBox);
  }

  void bleStop( ) {
    _setMessage('bleStoped');
  }

  int _counter = 0;
  double _vBat = 0;
  double _tWine = 0;
  double _tEnv = 0;
  int _rSSI = 0;
  int _minute = 0;
  int _secunds = 0;

  void _fillFromVineBox( VinoBox vinoBox) {
    setState(() {
      _counter = vinoBox.getPacketCounter();
      _vBat = 1.0*vinoBox.getBatt()/100;
      _tWine = 1.0*vinoBox.getWinTemp()/10;
      _tEnv = 1.0*(vinoBox.getExtTemp()-1000)/10;
      _rSSI = vinoBox.getRSSI();
      if( _epoch>0) {
        DateTime dateTime = DateTime.now();
        int sec = (dateTime.millisecondsSinceEpoch - _epoch)~/1000;
        _minute = sec~/60;
        _secunds = sec - 60*_minute;
      }
    });
    _startNotification();
  }

  bool _isTemperatureReached = false;

  void _startNotification() {
    if(_isTemperatureReached || _tWine == 0) {
      return;
    }
    if(_tWine <= _targetTemp) {
      _isTemperatureReached = true;
      _notification.sendTargetReached();
      _epoch = 0;
    }
  }

  static const String _idle = "Idle";
  static const String _scan = "Scan";
  static const String _read = "Read";
  String _msg = _idle;
  int _epoch = 0;
  int _findTime = 0;

  @override
  void initState() {
    super.initState();
    _notification.init();
  }

  bool isChecking = false;

  double _targetTemp = 14.0;

  void _plusPressed() {
    if( _targetTemp >= 30) {
      return;
    }
    setState(() {
      _targetTemp += _incTemp;
    });
  }

  void _presetPressed( double temperature) {
    setState(() {
      _targetTemp = temperature;
    });
  }

  static const double _incTemp = 0.5;

  void _minusPressed() {
    if( _targetTemp <= 0) {
      return;
    }
    setState(() {
      _targetTemp -= _incTemp;
    });
  }

  void _floatPressed() {
    _isTemperatureReached = false;
    setState(() {
      if(!isStart) {
        _floatStr = _stop;
        _floatColor = Colors.pink;
        _bleDevice.init();
//              _initProgressBegin();
        _epoch = DateTime.now().millisecondsSinceEpoch;
      }
      else {
        _floatStr = _start;
        _floatColor = Colors.green;
        _bleDevice.stop();
//              _notification.sendTargetReached();
//              _initProgressStop();
        _epoch = 0;
      }
      isStart = !isStart;
//            _showDialog();
    });
  }

  static const String _start = "Start";
  static const String _stop = "Stop";
  String _floatStr = _start;
  bool isStart = false;
  Color _floatColor = Colors.green;
  static const double _fontPlus = 40.0;

  bool _debug = false;

//  void _setVisability( bool bleStrted) {
//    _plusButton.visible = !bleStrted;
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility( child: PlusMinusButton( '-', _minusPressed), visible: !isStart, ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('$_targetTemp',
                         style: TextStyle(
                            fontSize: _fontPlus,
                            fontWeight: FontWeight.bold,
                           textBaseline: TextBaseline.alphabetic
                        ),
                      ),
                      Text('цель t°',
                        style: TextStyle(
                            fontSize: 25.0,
                            fontWeight: FontWeight.bold,
                            textBaseline: TextBaseline.alphabetic
                        ),
                      ),
                    ],
                  ),
                  Visibility( child: PlusMinusButton(  '+', _plusPressed), visible: !isStart, ),
                ]
            ),
            PresetTempButton( "Красное вино", Color( 0xFF7b002c), Colors.white, 14.0, _presetPressed, !isStart),
            PresetTempButton( "Белое вино", Colors.white, Colors.black, 10.0, _presetPressed, !isStart),
            PresetTempButton( "Шампаское", Color(0xDAFAFAD2), Colors.black, 8.0, _presetPressed, !isStart),
            Visibility( child: SizedBox(height: 30) , visible: !isStart, ),
            Visibility( child: SizedBox(height: 10) , visible: isStart, ),
            Visibility( child:
              Text(
                '$_msg',
                style: Theme.of(context).textTheme.title,
              ),
              visible: isStart,
            ),
            Visibility( child: SizedBox(height: 20) , visible: isStart, ),
            Visibility( child:
              SizedBox(width: 80, height: 80, child: CircularProgressIndicator( strokeWidth: 5.0)),
              visible: isStart && _bleDevice.IsConnected(),
            ), //CircularProgressIndicator()
            Visibility( child:
              Text(
                '$_counter',
                    style: Theme.of(context).textTheme.display1,
                ),
                visible: _debug  && isStart,
            ),
            Visibility( child: SizedBox(height: 20) , visible: isStart, ),
           Visibility( child:
              Text(
                  'Факт: '+'$_tWine' + '°C',
                  style: TextStyle(
                      fontSize: 35.0,
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic,
                      color: Colors.blue,
                  ),
                ),
              visible: isStart,
            ),
            Visibility( child:
              Text(
                        'Ext t: '+'$_tEnv' + '°C',
                        style: Theme.of(context).textTheme.display1,
                      ),
              visible: _debug && isStart,
            ),
            Visibility( child:
              Text(
                        'Batt: '+'$_vBat'+'V',
                        style: Theme.of(context).textTheme.display1,
                      ),
              visible: _debug && isStart,
            ),
            Visibility( child:
              Text(
                      'RSSI: '+'$_rSSI',
                      style: Theme.of(context).textTheme.display1,
                    ),
              visible: _debug  && isStart,
            ),
            Visibility( child:
              Text(
                        'Minutes: '+'$_minute'+':'+'$_secunds',
                        style: Theme.of(context).textTheme.display1,
                      ),
                visible: _debug  && isStart,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _floatPressed,
        tooltip: 'Star_BLE',
        label: Text("$_floatStr",
          style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              textBaseline: TextBaseline.alphabetic
          ),),
        backgroundColor: _floatColor,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Timer _initTimer;
  int _initCounter = 0;

  void _initProgressBegin() {
    if( _initTimer != null) {
      return;
    }
    _initCounter = 0;
    Duration period = Duration(milliseconds:1000);
    _initTimer = new Timer.periodic(period, (Timer t) {
      _initCounter++;
      if(_initCounter >= _initTimeLimit) {
        _initProgressStop();
        return;
      }
      _setMessage('Соединяемся... ${_initCounter} из ${_initTimeLimit} сек.');
    });
  }

  void _initProgressStop() {
//    _setMessage('');
    if( _initTimer == null) {
      return;
    }
    _initTimer.cancel();
    _initTimer = null;
  }

  void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Вино охладилось!"),
          content: new Text("Пожалуйста, достаньте бутылку изхолодильника и выключите гаджет. Иначе мы вынесем Вам мозг..."),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Уяснил"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void tmp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String contentText = "Content of Dialog";
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Title of Dialog"),
              content: Text(contentText),
              actions: <Widget>[
                FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                FlatButton(
                  onPressed: () {
                    setState(() {
                      contentText = "Changed Content of Dialog";
                    });
                  },
                  child: Text("Change"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

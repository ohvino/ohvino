import 'dart:async';

import 'package:flutter/services.dart';

import 'main.dart';

class BleDevice {
  final MyHomePageState _myHomePage;
  final int _waitLimit;
  BleDevice(this._myHomePage, this._waitLimit) ;

  static const channel_start = const MethodChannel('ble.ohvino.ru/start_ble');
  static const channel_stop = const MethodChannel('ble.ohvino.ru/stop_ble');
  static const channel_check = const MethodChannel( 'ble.ohvino.ru/check_ble');
  static const channel_limit = const MethodChannel( 'ble.ohvino.ru/limit_ble');

  int _limitSet = 0;

  bool _isConnected = false;
  bool IsConnected() {return  _isConnected;}

  String _resultStr;
  VinoBox _vinoBox = VinoBox();

  Future<void> _setWaitLimit() async {
    _limitSet = 0;
    try {
      _limitSet = await channel_limit.invokeMethod('limit_ble', {"limit":_waitLimit*1000});
    } on PlatformException catch (e) {
      _myHomePage.bleInitFlutterError( e.message);
      return;
    }
    if(_limitSet==0) {
      _myHomePage.bleLimitSetError();
      return;
    }
  }

  Future<void> init() async {
    _setWaitLimit();
    int result = -1;
    try {
      result = await channel_start.invokeMethod('start_ble');
    } on PlatformException catch (e) {
      _myHomePage.bleInitFlutterError( e.message);
      return;
    }

    if( result>=ERR.SERIOUS && result < 0) {
      _myHomePage.bleInitError(result);
      return;
    }
    _myHomePage.bleInitSuccess();
    _connect();
  }

  Timer _checkTimer;
  bool _isChecking = false;
  int _connectingTimeElapsed = 0;
  bool _isCheckError = false;

  void _connect() {
    _checkTimer = null;
    _isChecking = false;
     _connectingTimeElapsed = 0;
    Duration period = Duration(milliseconds:1000);
    _checkTimer = new Timer.periodic(period, (Timer t) {
      if(_connectingTimeElapsed>=_waitLimit) {
        _stopTimer();
        _myHomePage.bleConnectError(_vinoBox.getError());
        return;
      }
      _connectingTimeElapsed++;
      if(_isChecking) {
        return;
      }
      _isChecking = true;
      _checkBle();
    });
  }

  void _bleDataReceived() {
    if( _connectingTimeElapsed !=0) { // from coonecting
      _stopTimer();
      _myHomePage.bleIsConnected();
      _readDataStart();
      return;
    }
    _isConnected = true;
    _myHomePage.bleCheckSuccess( _vinoBox);
  }

  void _bleDataError() {
    _isConnected = false;
    _isCheckError = true;
  }

  Future<void> _checkBle() async {
     try {
      _resultStr = await channel_check.invokeMethod('check_ble');
    } on PlatformException catch (e) {
      _myHomePage.bleCheckFlutterError( e.message);
      return;
    }
    _vinoBox.setData(_resultStr);
    if(!_vinoBox.isError() ) {
      _bleDataReceived();
    }
    else {
      _bleDataError();
    }
    _isChecking = false;
  }

  void _readDataStart() {
    if( _checkTimer != null) {
      return;
    }
    _connectingTimeElapsed = 0;
    Duration period = Duration(milliseconds:1000);
    _checkTimer = new Timer.periodic(period, (Timer t) {
      if(_isChecking) {
        return;
      }
      _isChecking = true;
      _checkBle();
    });
  }

  void _stopTimer() {
    if( _checkTimer != null) {
      _checkTimer.cancel();
      _checkTimer = null;
      return;
    }
  }

  Future<void> stop() async {
    bool result = false;
    try {
      result = await channel_stop.invokeMethod('stop_ble');
    } on PlatformException catch (e) {
      _myHomePage.bleInitFlutterError( e.message);
      return;
    }
    if( result) {
      _connectingTimeElapsed = 0;
      _stopTimer();
      _myHomePage.bleStop();
      return;
    }
  }

}
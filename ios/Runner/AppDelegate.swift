import UIKit
import Flutter

class ERR {
    //serious
    public static let BLE_NOT_SUPPORTED  :  NSNumber = -1;
    public static let CANNOT_GET_BLE_ADAPTER  :  NSNumber = -2;
    public static let BT_NOT_ENABLE  :  NSNumber = -3;
    public static let NO_BT_SCANNER  :  NSNumber = -4;

    public static let NO_LOCATION_PERMISSION  :  NSNumber = -5;
    public static let SERIOUS  :  NSNumber = -5;
    // not serious
    public static let NO_BT_DEVICE  :  NSNumber = -6;
    public static let NO_BT_GATT  :  NSNumber = -7;
    public static let NOT_FOUND_DEVICE  :  NSNumber = -8;
    public static let NOT_CONNECTED_DEVICE  :  NSNumber = -9;
    public static let BT_BATCH_SCAN  :  NSNumber = -10;
    public static let BT_SCAN_FAILED  :  NSNumber = -11;
    public static let BT_SERVICE_NOT_FOUND  :  NSNumber = -12;
    public static let BT_CANT_READ  :  NSNumber = -13;
    public static let BT_CHAR_NOT_FOUND  :  NSNumber = -14;
    public static let BT_DESCR_NOT_FOUND  :  NSNumber = -15;
    public static let BT_CANT_NOTIFIED :  NSNumber = -16;
    
    public static let BT_UNKNOWN :  NSNumber = -1000;
}

//let myBle = MyBle()

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

	let CHANNEL_START = "ble.ohvino.ru/start_ble";
	let CHANNEL_STOP = "ble.ohvino.ru/stop_ble";
	let CHANNEL_CHECK = "ble.ohvino.ru/check_ble";
	let CHANNEL_LIMIT = "ble.ohvino.ru/limit_ble";//
	let NAME = "AhVino";

	var SCAN_PERIOD = 25000
    
    var _count=0

	override func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        let myBle = MyBle()
//        myBle.bleStart()
//        MyBle.sharedInstance.bleStart()

		let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

		let startChannel = FlutterMethodChannel(name: CHANNEL_START,
				                      binaryMessenger: controller.binaryMessenger)
		startChannel.setMethodCallHandler({
			(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            MyBle.sharedInstance.bleStart()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `1.0` to the desired number of seconds.
                result( MyBle.sharedInstance.GetError())
           }
		})

		let limitChannel = FlutterMethodChannel(name: CHANNEL_LIMIT,
				                      binaryMessenger: controller.binaryMessenger)
		limitChannel.setMethodCallHandler({
			(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
			guard let args = call.arguments else {
				return
			}
			if let myArgs = args as? [String: Any],
				let tmpLimit = myArgs["limit"] as? Int {
                self.SCAN_PERIOD = tmpLimit
					result( 1)
				}
			else {
				result( 0)
			}
		})

		let checkChannel = FlutterMethodChannel(name: CHANNEL_CHECK,
				                      binaryMessenger: controller.binaryMessenger)
		checkChannel.setMethodCallHandler({
			(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
	      if !MyBle.sharedInstance.IsConnected() {
		 result( "Error: " + String( format: "%04d", MyBle.sharedInstance.GetError())
		return
	      }
 //           self._count+=1
 //           let resStr = String(format: "%04d", self._count)+"1630331111-86 ";
            result(MyBle.sharedInstance.GetResult());
		})

		let stopChannel = FlutterMethodChannel(name: CHANNEL_STOP,
				                      binaryMessenger: controller.binaryMessenger)
		stopChannel.setMethodCallHandler({
			(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
				result( true)
		})

		GeneratedPluginRegistrant.register(with: self)
		return super.application(application, didFinishLaunchingWithOptions: launchOptions)
	}
}


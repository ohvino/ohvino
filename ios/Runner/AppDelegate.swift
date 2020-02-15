import UIKit
import Flutter

class ERR {
    //serious
    public static let BLE_NOT_SUPPORTED = -1;
    public static let CANNOT_GET_BLE_ADAPTER = -2;
    public static let BT_NOT_ENABLE = -3;
    public static let NO_BT_SCANNER = -4;

    public static let NO_LOCATION_PERMISSION = -5;
    public static let SERIOUS = -5;
    // not serious
    public static let NO_BT_DEVICE = -6;
    public static let NO_BT_GATT = -7;
    public static let NOT_FOUND_DEVICE = -8;
    public static let NOT_CONNECTED_DEVICE = -9;
    public static let BT_BATCH_SCAN = -10;
    public static let BT_SCAN_FAILED = -11;
    public static let BT_SERVICE_NOT_FOUND = -12;
    public static let BT_CANT_READ = -13;
    public static let BT_CHAR_NOT_FOUND = -14;
    public static let BT_DESCR_NOT_FOUND = -15;
    public static let BT_CANT_NOTIFIED = -16;
}

//let myBle = MyBle()

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

	let CHANNEL_START = "ble.ohvino.ru/start_ble";
	let CHANNEL_STOP = "ble.ohvino.ru/stop_ble";
	let CHANNEL_CHECK = "ble.ohvino.ru/check_ble";
	let CHANNEL_LIMIT = "ble.ohvino.ru/limit_ble";
	let NAME = "AhVino\r\n";

	var SCAN_PERIOD = 25000
    
    var _count=0

	override func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        let myBle = MyBle()
//        myBle.bleStart()
        MyBle.sharedInstance.bleStart()

		let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

		let startChannel = FlutterMethodChannel(name: CHANNEL_START,
				                      binaryMessenger: controller.binaryMessenger)
		startChannel.setMethodCallHandler({
			(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
			result( 0)
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
            self._count+=1
            let resStr = String(format: "%04d", self._count)+"1230331111-86 ";
            result(resStr);
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


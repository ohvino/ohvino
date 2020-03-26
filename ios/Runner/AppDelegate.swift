import UIKit
import Flutter

class ERR {
    //serious
    public static let BLE_NOT_SUPPORTED  :  Int = -1;
    public static let CANNOT_GET_BLE_ADAPTER  :  Int = -2;
    public static let BT_NOT_ENABLE  :  Int = -3;
    public static let NO_BT_SCANNER  :  Int = -4;

    public static let NO_LOCATION_PERMISSION  :  Int = -5;
    public static let SERIOUS  :  Int = -5;
    // not serious
    public static let NO_BT_DEVICE  :  Int = -6;
    public static let NO_BT_GATT  :  Int = -7;
    public static let NOT_FOUND_DEVICE  :  Int = -8;
    public static let NOT_CONNECTED_DEVICE  :  Int = -9;
    public static let BT_BATCH_SCAN  :  Int = -10;
    public static let BT_SCAN_FAILED  :  Int = -11;
    public static let BT_SERVICE_NOT_FOUND  :  Int = -12;
    public static let BT_CANT_READ  :  Int = -13;
    public static let BT_CHAR_NOT_FOUND  :  Int = -14;
    public static let BT_DESCR_NOT_FOUND  :  Int = -15;
    public static let BT_CANT_NOTIFIED :  Int = -16;
    
    public static let BT_UNKNOWN :  Int = -1000;
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
            print("CHANNEL_CHECK called")
            if !MyBle.sharedInstance.IsConnected() {
                let err = MyBle.sharedInstance.GetError()
                print("CHANNEL_CHECK error \(err)")
                result( "Error: " + String( format: "%04d", err))
                return
            }
            //           self._count+=1
            //           let resStr = String(format: "%04d", self._count)+"1630331111-86 ";
            let str = MyBle.sharedInstance.GetResult() + " "
            print("CHANNEL_CHECK finished \(str)")
            result( str);
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


//
//  ble.swift
//  Runner
//
//  Created by admin on 15/02/2020.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import CoreBluetooth

private let sharedManager = MyBle()

class MyBle: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let bleName = "AhVino"
    
    private var mError : NSNumber = 0
    func GetError() -> NSNumber {
        return mError
    }

    private var mResult = ""
    func GetResult() -> String {
        return mResult
    }

    func IsConnected() -> Bool {
        return mError==0
    }
   

    var central_manager: CBCentralManager! = nil

    // Singleton instance
    class var sharedInstance: MyBle {
        struct Static {
            static let instance: MyBle = MyBle()
        }
        return Static.instance
    }

    //peripheral manager
    var myPeripheral: CBPeripheral?
    var myService: CBService?
    var myCharacteristic: CBCharacteristic?

    //HM-10 service code
    let HMServiceCode = CBUUID(string: "0xFFE0")
 //   let HMServiceCode = CBUUID(string: "0x0000ffe000001000800000805f9b34fb")

    //HM-10 characteristic code
    let HMCharactersticCode = CBUUID(string: "0xFFE1")

    //array to store the peripherals
    var peripheralArray:[(peripheral: CBPeripheral, RSSI: Float)] = []

    //for timing..obvs
    var timer: Timer!
    
/*    public override init() {
        super.init()
        self.central_manager = CBCentralManager.init(delegate: self, queue: nil)
    }
*/
    deinit {
        if central_manager == nil {
            return
        }
        if let myPeripheral = myPeripheral {
            switch (myPeripheral.state) {
            case.connected:
                self.central_manager.cancelPeripheralConnection( myPeripheral)
                print( "disconnect")
            case .disconnected:
                print( "disconnected")
            case .connecting:
                print( "connecting")
            case .disconnecting:
                print( "disconnecting")
            }
        }
    }
    func bleStart() {
        mError = ERR.BT_UNKNOWN
        if central_manager == nil {
            central_manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true, CBCentralManagerOptionShowPowerAlertKey: true])
        }
    }

    //MARK: Bluetooth central

    //required centralmanager component. Text for what power state currently is
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        var consoleMsg = ""
        switch (central.state) {
        case.poweredOff:
            consoleMsg = "BLE is Powered Off"
            mError = ERR.BT_NOT_ENABLE
        case.poweredOn:
            consoleMsg = "BLE is Powered On"
            mError = ERR.BT_SCAN_FAILED
            self.startScan()
         case.resetting:
            consoleMsg = "BLE is resetting"
        case.unknown:
            consoleMsg = "BLE is in an unknown state"
        case.unsupported:
            consoleMsg = "This device is not supported by BLE"
            mError = ERR.BLE_NOT_SUPPORTED
        case.unauthorized:
            consoleMsg = "BLE is not authorised"
        }
        print("\(consoleMsg)")
    }

    //MARK: scanning
    //press scan button to initiate scanning sequence
    func startScan() {
        startTimer()
    }

    //start scanning for 10 seconds
    func startTimer()  {
        //after 5 seconds this goes to the stop scanning routine
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(MyBle.stopScanning), userInfo: nil, repeats: true)
        print("Start Scan")
        central_manager?.scanForPeripherals(withServices: nil, options: nil)
//        central_manager?.scanForPeripherals(withServices: [HMServiceCode], options: nil)
    }
    //stop the scanning and re-enable the scan button so you can do it again
    @objc func stopScanning()
    {
        timer?.invalidate()
        print("timer stopped")
        central_manager?.stopScan()
        print("Scan Stopped")
        print("array items are: \(peripheralArray)")
//        print("peripheral items are: \(peripheral)")
//        print("manager items are: \(central_manager)")
    }

    //MARK: Connection to bluetooth
    //once scanned this will say what has been discovered - add to peripheralArray
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        for existing in peripheralArray
        {
            if existing.peripheral.identifier == peripheral.identifier {return}
        }
        //adding peripheral to the array
        let theRSSI = RSSI.floatValue
//        peripheralArray.append([ peripheral, theRSSI])
        peripheralArray.append( (peripheral: peripheral, RSSI: theRSSI))
        if peripheral.name!.starts( with: bleName) {
            self.stopScanning();
            myPeripheral = peripheral
            print("AhVino found")
            central.connect( peripheral, options: nil)
        }
        peripheralArray.sort { $0.RSSI < $1.RSSI }
        print("discovered peripheral")
        print("There are \(peripheralArray.count) peripherals in the array")
    }

    //create a link/connection to the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        mError = ERR.BT_SERVICE_NOT_FOUND
        myPeripheral = peripheral
        myPeripheral?.delegate = self
        myPeripheral?.discoverServices([HMServiceCode])
        print("connected to peripheral:\(peripheral)")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        print("didDiscoverServices begin")
        if let error = error {
            print("didDiscoverServices error: \(error)")
            return
        }
        let services = peripheral.services
//        print("found \(services.count) services! :\(services)")
        print( "services! :\(String(describing: services))")
        mError = ERR.BT_CHAR_NOT_FOUND
        for service in peripheral.services!
        {
            peripheral.discoverCharacteristics( nil, for: service)
//            peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        // check whether the characteristic we're looking for (0xFFE1) is present - just to be sure
        print("didDiscoverCharacteristicsFor begin")
        if let error = error {
             print("didDiscoverCharacteristicsFor error: \(error)")
             return
         }
        for characteristic in service.characteristics!
        {
            if characteristic.uuid == CBUUID(string: "FFE1")
            {
                mError = ERR.BT_DESCR_NOT_FOUND
                myService = service
                myCharacteristic = characteristic
                print( "FFE1 found")
                peripheral.discoverDescriptors(for: characteristic)
                peripheral.setNotifyValue(true, for: myCharacteristic!)
//                peripheral.readValue(for: myCharacteristic!)
             }
        }
    }
    
    private func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor service: CBService, error: Error?)
    {
        print("didDiscoverDescriptorsFor begin")
        if let error = error {
             print("didDiscoverDescriptorsFor error: \(error)")
             return
        }
//        peripheral.setNotifyValue(true, for: myCharacteristic!)
//        peripheral.readValue(for: myCharacteristic!)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor begin")
        if let error = error {
            print("didUpdateNotificationStateFor error: \(error)")
            mError = ERR.BT_CANT_NOTIFIED
            return
        }
        print ("didUpdateNotificationStateFor: ok")
//        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor begin")
        if let error = error {
            print("didUpdateValueFor error: \(error)")
            mError = ERR.BT_CANT_READ
            return
        }
        print ("didUpdateValueFor: \(characteristic)")
        mError = 0
        let data = characteristic.value
        let str = String(data: data!, encoding: String.Encoding.ascii) //utf8)
        mResult = String(str!.prefix(14))
        print ("didUpdateValueFor data: \(mResult)")
        peripheral.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("didReadRSSI begin")
        if let error = error {
            print("didReadRSSI error: \(error)")
            mError = ERR.BT_CANT_READ
            return
        }
        let ptsString = String(format: "%d", RSSI)
        print ("didReadRSSI ptsString: \(ptsString)")
        mResult += ptsString
        print ("didReadRSSI: \(mResult) \(RSSI)")
    }

    //disconnect from the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("disconnected from peripheral")
        mError = ERR.NOT_CONNECTED_DEVICE
        stopScanning()
    }

    //if it failed to connect to a peripheral will tell us (although not why)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        print("failed to connect to peripheral")
        mError = ERR.NOT_CONNECTED_DEVICE
        stopScanning()
    }


}

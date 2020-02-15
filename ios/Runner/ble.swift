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

    var central_manager: CBCentralManager! = nil

    // Singleton instance
    class var sharedInstance: MyBle {
        struct Static {
            static let instance: MyBle = MyBle()
        }
        return Static.instance
    }

    //peripheral manager
    var peripheral: CBPeripheral?

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
    func bleStart() {
        if central_manager == nil {
            central_manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true, CBCentralManagerOptionShowPowerAlertKey: true])
        }
    }

    //MARK: Bluetooth central

    //required centralmanager component. Text for what power state currently is
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        var consoleMsg = ""
        switch (central.state)
        {
        case.poweredOff:
            consoleMsg = "BLE is Powered Off"
        case.poweredOn:
            consoleMsg = "BLE is Powered On"
            self.startScan()
         case.resetting:
            consoleMsg = "BLE is resetting"
        case.unknown:
            consoleMsg = "BLE is in an unknown state"
        case.unsupported:
            consoleMsg = "This device is not supported by BLE"
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
        peripheralArray.sort { $0.RSSI < $1.RSSI }
        print("discovered peripheral")
        print("There are \(peripheralArray.count) peripherals in the array")
    }

    //create a link/connection to the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        peripheral.discoverServices(nil) //may need to remove this not sure it does much
        print("connected to peripheral")
    }

    //disconnect from the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("disconnected from peripheral")
        stopScanning()
    }

    //if it failed to connect to a peripheral will tell us (although not why)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        print("failed to connect to peripheral")
        stopScanning()
    }


}

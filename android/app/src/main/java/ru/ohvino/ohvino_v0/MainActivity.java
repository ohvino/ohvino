package ru.ohvino.ohvino_v0;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;

//import io.flutter.Log;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.content.Intent;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.UUID;

import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.os.Looper;
import android.util.Log;
import android.widget.Toast;

import java.util.List;

class ERR {
    //serious
    public static final int BLE_NOT_SUPPORTED = -1;
    public static final int CANNOT_GET_BLE_ADAPTER = -2;
    public static final int BT_NOT_ENABLE = -3;
    public static final int NO_BT_SCANNER = -4;

    public static final int NO_LOCATION_PERMISSION = -5;
    public static final int SERIOUS = -5;
    // not serious
    public static final int NO_BT_DEVICE = -6;
    public static final int NO_BT_GATT = -7;
    public static final int NOT_FOUND_DEVICE = -8;
    public static final int NOT_CONNECTED_DEVICE = -9;
    public static final int BT_BATCH_SCAN = -10;
    public static final int BT_SCAN_FAILED = -11;
    public static final int BT_SERVICE_NOT_FOUND = -12;
    public static final int BT_CANT_READ = -13;
    public static final int BT_CHAR_NOT_FOUND = -14;
    public static final int BT_DESCR_NOT_FOUND = -15;
    public static final int BT_CANT_NOTIFIED = -16;
}

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL_START = "ble.ohvino.ru/start_ble";
    private static final String CHANNEL_STOP = "ble.ohvino.ru/stop_ble";
    private static final String CHANNEL_CHECK = "ble.ohvino.ru/check_ble";
    private static final String CHANNEL_LIMIT = "ble.ohvino.ru/limit_ble";
    private static final String NAME = "AhVino\r\n";

//    Result mFlutterResult = null;
    private void SendToFlutter(int res) {
//        if( mFlutterResult == null) {
//            return;
//        }
//        mFlutterResult.success(res);
//        mFlutterResult = null;
    }

    private final static int RESULT_UNDEF=-1;
    private final static int RESULT_NO=-1;
    private static int mResult=RESULT_UNDEF;
    private static int mError=0;
    private static String strResult = "Undef";
    private static int mRSSI=0;

    private static final int N_=-1;

    public final String strNotConnected = "Not connected";
    boolean realConnection = false;

    public static int _counter=0;

    private long SCAN_PERIOD = 25000;

    private class MyBle {
        //private int mResult=0;

        private BluetoothAdapter mBluetoothAdapter = null;
        private boolean mScanning;
        private BluetoothDevice mBluetoothDevice = null;
        private BluetoothGatt  mBluetoothGatt = null;

        public final UUID HM_10_SERVICE= UUID.fromString("0000ffe0-0000-1000-8000-00805f9b34fb"); //characteristic
        public final UUID HM_10_CHARACTER= UUID.fromString("0000ffe1-0000-1000-8000-00805f9b34fb");
        public final UUID HM_10_DESCRIPTOR= UUID.fromString("00002902-0000-1000-8000-00805F9B34FB");
        private BluetoothGattCharacteristic mCharacteristic = null;
        BluetoothGattDescriptor mDescriptor = null;
        private int _readCount = 0;

//        private Handler readHandler = new Handler();
        public BluetoothAdapter GetBluetoothAdapter() {
            return mBluetoothAdapter;
        }

        private List<ScanFilter> mFilterList = new ArrayList<>();
        private final ScanFilter mScanFilter = new ScanFilter.Builder().setDeviceName(NAME).build();
//        private final ScanFilter mScanFilter = new ScanFilter.Builder();
        private final ScanSettings mScanSettings = new ScanSettings.Builder().setScanMode(ScanSettings.CALLBACK_TYPE_ALL_MATCHES).build();
        private BluetoothLeScanner mBleScanner=null;

        MyBle() {
            mError=0;
            mResult=RESULT_UNDEF;

            if(!checkLocationPermission()){
                mError= ERR.NO_LOCATION_PERMISSION;
                mResult=RESULT_NO;
                SendToFlutter(mError);
                return;
            }

            if(!CheckBtAdapter()) {
                mResult=RESULT_NO;
                SendToFlutter(mError);
                return;
            }

            ScanLeDevice();
        }

        public void Close() {
             if (mBluetoothGatt != null) {
                mBluetoothGatt.close();
            }
        }

        public void ReadCharacteristic() {
            mBluetoothGatt.readCharacteristic(mCharacteristic);
        }

        public boolean IsConnected() {
            if(mError <0 && mError>=ERR.NO_BT_SCANNER) {
                return false;
            }
            if(!checkLocationPermission()){
                mError= ERR.NO_LOCATION_PERMISSION;
                return false;
            }
            if( mBluetoothDevice == null) {
                mError= ERR.NO_BT_DEVICE;
                return false;
            }
            if( mBluetoothGatt == null ) {
                mError = ERR.NO_BT_GATT;
                return false;
            }
            if(!realConnection) {
                mError = ERR.NOT_CONNECTED_DEVICE;
                return false;
            }

            return true;
//            int res = mBluetoothGatt.getConnectionState( mBluetoothDevice);
//            if ( res == BluetoothProfile.STATE_CONNECTED) {
//                return true;
//            }
//            mError = ERR.NOT_CONNECTED_DEVICE;
//            return false;
        }

        private void fStopScan() {
            if(mScanning) {
                mBleScanner.stopScan(mScanCallback);
            }
            mScanning = false;
        }

        private Handler mHandler = new Handler();

        private ScanCallback mScanCallback = new ScanCallback() {

            @Override
            public void onScanResult(int callbackType, ScanResult result) {
                System.out.println("BLE// onScanResult");
                Log.i("callbackType", String.valueOf(callbackType));
                Log.i("result", result.toString());
                mBluetoothDevice = result.getDevice();
                fnd = System.currentTimeMillis() - epoch;
                 fStopScan();
                _counter++;
                ConnectToDevice();
            }

            @Override
            public void onBatchScanResults(List<ScanResult> results) {
                System.out.println("BLE// onBatchScanResults");
                for (ScanResult sr : results) {
                    Log.i("ScanResult - Results", sr.toString());
                }
            }

            @Override
            public void onScanFailed(int errorCode) {
                System.out.println("BLE// onScanFailed");
                Log.e("Scan Failed", "Error Code: " + errorCode);
                mError=ERR.BT_SCAN_FAILED;
                SendToFlutter(mError);
            }
        };

        private boolean CheckBtAdapter() {
            // Use this check to determine whether BLE is supported on the device.  Then you can
            // selectively disable BLE-related features.
            if (!getPackageManager().hasSystemFeature( PackageManager.FEATURE_BLUETOOTH_LE)) {
                //Toast.makeText(MainActivity.this, "ble_not_supported", Toast.LENGTH_SHORT).show();
                mError = ERR.BLE_NOT_SUPPORTED;
                return false;
            }

            // Initializes a Bluetooth adapter.  For API level 18 and above, get a reference to
            // BluetoothAdapter through BluetoothManager.
            final BluetoothManager bluetoothManager =
                    (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
            mBluetoothAdapter = bluetoothManager.getAdapter();

            // Checks if Bluetooth is supported on the device.
            if (mBluetoothAdapter == null) {
                //Toast.makeText(MainActivity.this, "error_bluetooth_not_supported", Toast.LENGTH_SHORT).show();
                //         finish();
                mError = ERR.CANNOT_GET_BLE_ADAPTER;
                return false;
            }

            if (!mBluetoothAdapter.isEnabled()) {
                Intent enableIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                startActivityForResult(enableIntent, REQUEST_ENABLE_BT);
            }
            if (!mBluetoothAdapter.isEnabled()) {
                mError = ERR.BT_NOT_ENABLE;
                return false;
            }

            mBleScanner = mBluetoothAdapter.getBluetoothLeScanner();
            if (mBleScanner == null) {
                mError = ERR.NO_BT_SCANNER;
                return false;
            }

            return true;
        }

        private void ScanLeDevice() {
            if( mFilterList.size()==0) {
                mFilterList.add(mScanFilter);
            }
            // Stops scanning after a pre-defined scan period.
            mHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if(mScanning) {
                        fStopScan();
                        mError = ERR.NOT_FOUND_DEVICE;
                        SendToFlutter(mError);
                    }
                }
            }, SCAN_PERIOD);

            mScanning = true;
//            mBleScanner.startScan( mScanCallback);
            mBleScanner.startScan( mFilterList, mScanSettings, mScanCallback);
        }

        public void ConnectToDevice() {
            if (mBluetoothDevice == null) {
                System.out.println("myBle/connectToDevice()/ BluetoothDevice == null ");
                return;
            }
            System.out.println("BLE// connectToDevice()");
            if (mBluetoothGatt == null) {
                mBluetoothGatt = mBluetoothDevice.connectGatt(MainActivity.this, true, mBluetoothGattCallback); //Connect to a GATT Server
            }
        }

//        boolean _DescriptorWritten = true;

        private final BluetoothGattCallback mBluetoothGattCallback = new BluetoothGattCallback() {

            @Override
            public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                realConnection = false;
                System.out.println("BLE// BluetoothGattCallback");
                Log.i("onConnectionStateChange", "Status: " + status);
//                new Handler(Looper.getMainLooper()).postDelayed( () -> mBluetoothGatt.readRemoteRssi(), 3000);
                super.onConnectionStateChange(gatt, status, newState);
                switch (newState) {
                    case BluetoothProfile.STATE_CONNECTED:
                        Log.i("gattCallback", "STATE_CONNECTED");
                        gatt.discoverServices();
                        break;
                    case BluetoothProfile.STATE_CONNECTING:
                        Log.i("gattCallback", "STATE_CONNECTING");
                        break;
                    case BluetoothProfile.STATE_DISCONNECTED:
                        Log.i("gattCallback", "STATE_DISCONNECTED");
                        gatt.connect();
                        break;
                    default:
                        Log.e("gattCallback", "STATE_OTHER");
                }
            }

            @Override
            //New services discovered
            public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                BluetoothGattService service = gatt.getService(HM_10_SERVICE);
                if( service!=null) {
                    Log.i("onServicesDiscovered", service.toString());
                    mCharacteristic = service.getCharacteristic(HM_10_CHARACTER);
                    if( mCharacteristic == null) {
                        Log.i("onServicesDiscovered", "HM-10 characteristic hasn't discovered.");
                        mError=ERR.BT_CHAR_NOT_FOUND;
                        SendToFlutter(mError);
                        return;
                    }
                    Log.i("onServicesDiscovered", "HM-10 characteristic has discovered.");
                    gatt.setCharacteristicNotification(mCharacteristic, true);
                    mDescriptor = mCharacteristic.getDescriptor(HM_10_DESCRIPTOR);
                    if(mDescriptor==null) {
                        Log.i("onServicesDiscovered", "HM-10 descriptor hasn't discovered.");
                        mError = ERR.BT_DESCR_NOT_FOUND;
                        SendToFlutter(mError);
                        return;
                    }
                    gatt.readCharacteristic(mCharacteristic);
//                    if (!mBluetoothGatt.requestConnectionPriority(mBluetoothGatt.CONNECTION_PRIORITY_LOW_POWER)) {
//                        _readCount=-1;
//                    }
//                    StartRead();

                }
                else {
                    Log.i("onServicesDiscovered", "HM-10 service hasn't discovered.");
                    mError=ERR.BT_SERVICE_NOT_FOUND;
                    SendToFlutter(mError);
                    return;
                 }
            }

            @Override
            //Result of a characteristic read operation
            public void onCharacteristicRead(BluetoothGatt gatt,
                                             BluetoothGattCharacteristic
                                                     characteristic, int status) {
                if( status!=BluetoothGatt.GATT_SUCCESS ) {
                    Log.i("onCharacteristicRead", new String("Reading fall ") + status);
                    mError=ERR.BT_CANT_READ;
                    SendToFlutter(mError);
                    return;
                }
//                if(mDescriptor!=null  && !_DescriptorWritten) {
//                    Log.i("onCharacteristicRead", new String("Descriptor Written"));
//                    _DescriptorWritten = true;
//                    mDescriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
//                    gatt.writeDescriptor(mDescriptor);
//                }
//                CharacteristicExec(characteristic.getValue());
//                FillStrResult(characteristic.getValue());
                FillStrResult(new String("00000000000000").getBytes());
          }

            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
               //super.onCharacteristicChanged(gatt, characteristic);
                Log.i("onCharacteristicChanged", "Characteristic Changed");
 //               gatt.readRemoteRssi();
 //               CharacteristicExec(characteristic.getValue());
                FillStrResult(characteristic.getValue());
                gatt.readRemoteRssi();
            }

            @Override
            public void onReadRemoteRssi (BluetoothGatt gatt, int rssi, int status) {
                //super.onCharacteristicChanged(gatt, characteristic);
                Log.i("onReadRemoteRssi", "RSSI " + rssi);
                mRSSI = rssi;
             }

            void CharacteristicExec( byte[] val) {
                int sum=0;
                for( int i=5; i>=0; i--) {
                    sum=sum*10 + val[i];
                }
                String charString = "characteristic";
                _readCount++;
                Log.i("onCharacterRead count", charString + " "+sum +"<>" + _readCount);
//                gatt.disconnect();
                SendToFlutter( sum);
            }
        };

//        private boolean isReading=false;
//        public boolean IsReading() {
//            return isReading;
//        }
//
//        final int mReadPeriod = 3000;
//        Runnable _runnable = new Runnable() {
//            @Override
//            public void run() {
//                if (!isReading) {
//                    return;
//                }
//                 if (mCharacteristic != null) {
//                     _counter++;
//                     mBluetoothGatt.readCharacteristic(mCharacteristic);
//                }
//                readHandler.postDelayed(this, mReadPeriod);
//            }
//        };
//
//        public void StartRead() {
////            if( !IsConnected()) {
////                return;
////            }
//            isReading = true;
//            _readCount = 0;
//            readHandler.postDelayed(_runnable, mReadPeriod);
//        }
//
//        public void StopRead() {
////            readHandler.removeCallbacks(runnable);
//            isReading = false;
//        }

    }

    private static final int REQUEST_ENABLE_BT = 1;
    private static final int PERMISSION_REQUEST_COARSE_LOCATION = 1;

    MyBle myBle = null;

    private boolean isLocationGranted = false;

    public boolean checkLocationPermission(){
        if(isLocationGranted) {
            return true;
        }

        int permissionCheck = ContextCompat.checkSelfPermission(MainActivity.this, android.Manifest.permission.ACCESS_COARSE_LOCATION);

        switch(permissionCheck){
            case PackageManager.PERMISSION_GRANTED:
                isLocationGranted = true;
                break;

            case PackageManager.PERMISSION_DENIED:

                if(ActivityCompat.shouldShowRequestPermissionRationale(MainActivity.this, android.Manifest.permission.ACCESS_COARSE_LOCATION)){
                    //Show an explanation to user *asynchronouselly* -- don't block
                    //this thread waiting for the user's response! After user sees the explanation, try again to request the permission

//                    Snackbar.make(view, "Location access is required to show Bluetooth devices nearby.",
//                            Snackbar.LENGTH_LONG).setAction("Action", null).show();
                    Toast.makeText(MainActivity.this, "Location access is required to show Bluetooth devices nearby.", Toast.LENGTH_SHORT).show();
                }
                ActivityCompat.requestPermissions(MainActivity.this, new String[]{android.Manifest.permission.ACCESS_COARSE_LOCATION}, PERMISSION_REQUEST_COARSE_LOCATION);
                permissionCheck = ContextCompat.checkSelfPermission(MainActivity.this, android.Manifest.permission.ACCESS_COARSE_LOCATION);
                if(permissionCheck == PackageManager.PERMISSION_GRANTED) {
                    isLocationGranted = true;
                    return true;
                }
                break;
        }
        return isLocationGranted;
    }

    @Override
  public void onCreate(Bundle savedInstanceState) {

    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

         new MethodChannel(getFlutterView(), CHANNEL_START).setMethodCallHandler(
            new MethodCallHandler() {
                @Override
                public void onMethodCall(MethodCall call, Result result) {
//                    mFlutterResult = result;
                    epoch = System.currentTimeMillis();
                    myBle = new MyBle();
                    result.success(mError);
                }
            });

        final DecimalFormat df = new DecimalFormat("000");

        new MethodChannel(getFlutterView(), CHANNEL_CHECK).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        if(!myBle.IsConnected()) {
                            result.success("Error: "+String.valueOf(mError));
                            return;
                        }
                        String str =  df.format(mRSSI);
                        strResult = strResult + str;
                        result.success(strResult);
                    }
                });

        new MethodChannel(getFlutterView(), CHANNEL_LIMIT).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        int limit = call.argument("limit");
                        SCAN_PERIOD = limit;
                        result.success(1);
                    }
                });

        new MethodChannel(getFlutterView(), CHANNEL_STOP).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        if(myBle != null) {
                            myBle.Close();
                            myBle = null;
                            Log.i("CHANNEL_STOP ", "Ble = null");
                        }
                        Log.i("CHANNEL_STOP ", "result true");
                        result.success(true);
                    }
                });
  }

  long epoch = 0;
  long fnd = 0;
  private void FillStrResult( byte[] bt) {
      strResult = new String(bt).substring(0,14);
      epoch = System.currentTimeMillis() - epoch;
      realConnection = true;
      Log.i("FillStrResult ", "character <>" + strResult);
  }
}

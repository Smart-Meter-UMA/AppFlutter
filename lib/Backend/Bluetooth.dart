import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothHelper{
  static Uuid smartMeterTokenUuid = Uuid.parse("544f4b4e-d32a-11ec-9d64-0242ac120002");
  static Uuid smartMeterWifiNameUuid = Uuid.parse("6bfe5343-d32a-11ec-9d64-0242ac120002");
  static Uuid smartMeterWifiPassUuid = Uuid.parse("760a51b2-d32a-11ec-9d64-0242ac120002");
  late final FlutterReactiveBle bluetooth;
  final List<DiscoveredDevice> discoveredDevices = List.empty(growable: true);
  final List<DiscoveredDevice> smartMeters = List.empty(growable: true);
  final List<List<DiscoveredService>> smartMetersServices = List.empty(growable: true);
  final List<List<List<SmartMeterCharacteristics>>> smartMetersCharacteristics = List.empty(growable: true);

  BluetoothHelper(){
    bluetooth = FlutterReactiveBle();
  }

  void scanForSmartMeters(void Function(bool, List<String>) onScanCompleted){
    discoveredDevices.clear();
    smartMeters.clear();
    smartMetersServices.clear();
    smartMetersCharacteristics.clear();
    bluetooth.deinitialize();
    bluetooth.initialize();

    DiscoveryResultHandler handler = DiscoveryResultHandler(
        discoveredDevices,
        onScanCompleted,
        this
    );
    scanForDevices(handler);
  }

  //Performs a BLE scan for all devices in range
  void scanForDevices(DiscoveryResultHandler handler){
    bool error = false;

    StreamSubscription subscription = bluetooth.scanForDevices(
        withServices: [], //Scan for all services
        scanMode: ScanMode.lowLatency
    ).listen(
        handler.onDeviceDiscovered,
        onError: (Object e, StackTrace trace){
          handler.onDiscoveryError(e, trace); error = true;
        },
        cancelOnError: true
    );

    Future.delayed(const Duration(seconds: 5), () async {
      await subscription.cancel();

      if(!error){
        handler.onDiscoveryCompleted();
      }
    });
  }

  ///Connects to a device, returns if the connection was successful
  void connect(int index, void Function(bool) callback) async {
    List<Uuid> servicesUuid = List.generate(
      smartMetersServices.length, 
      (serviceIndex) => smartMetersServices.elementAt(index).elementAt(serviceIndex).serviceId
    );
    bluetooth.connectToAdvertisingDevice(
        id: smartMeters.elementAt(index).id,
        withServices: servicesUuid,
        prescanDuration: const Duration(seconds: 5)
    ).listen((state) {
      if(state.connectionState == ConnectionStatus.connected){
        callback(true);
      }
    }).onError(
      (error) => callback(false)
    );
  }

  //Search all the discovered devices for Smart Meters,
  //returns the names of the discovered Smart Meters
  Future<List<String>> analiseDiscoveredDevices() async {
    List<String> names = List.empty(growable: true);
    
    for (DiscoveredDevice device in discoveredDevices) {
      List<DiscoveredService> services = await bluetooth.discoverServices(
        device.id);

      bool isSmartMeter = false;
      for (DiscoveredService service in services) {
        bool isSmartMeterService = false;
        if (service.characteristicIds.contains(smartMeterTokenUuid) &&
            service.characteristicIds.contains(smartMeterTokenUuid) &&
            service.characteristicIds.contains(smartMeterTokenUuid)) {
          isSmartMeter = true;
          isSmartMeterService = true;

          smartMetersCharacteristics.last.last.add(SmartMeterCharacteristics(
            service.characteristics.firstWhere(
                    (characteristic) =>
                characteristic.characteristicId == smartMeterTokenUuid),
            service.characteristics.firstWhere(
                    (characteristic) =>
                characteristic.characteristicId == smartMeterWifiNameUuid),
            service.characteristics.firstWhere(
                    (characteristic) =>
                characteristic.characteristicId == smartMeterWifiPassUuid),
          ));
        }

        if(isSmartMeterService){
          smartMetersServices.last.add(service);
        }
      }

      if(isSmartMeter){
        smartMeters.add(device);
        names.add(device.name);
      }
    }
    
    return names;
  }

  Future<String?> readToken(int index) async{
    return readFromCharacteristic(
        smartMeters.elementAt(index).id,
        smartMetersServices.elementAt(index).first.serviceId,
        smartMeterTokenUuid
    );
  }

  Future<String?> readWifiName(int index) async{
    return readFromCharacteristic(
        smartMeters.elementAt(index).id,
        smartMetersServices.elementAt(index).first.serviceId,
        smartMeterWifiNameUuid
    );
  }

  Future<String?> readWifiPass(int index) async{
    return readFromCharacteristic(
        smartMeters.elementAt(index).id,
        smartMetersServices.elementAt(index).first.serviceId,
        smartMeterWifiPassUuid
    );
  }

  Future<bool> writeToken(int index, String data) async{
    return writeCharacteristic(
        smartMeters.elementAt(index).id,
        smartMetersServices.elementAt(index).first.serviceId,
        smartMeterTokenUuid,
        data
    );
  }

  Future<bool> writeWifiName(int index, String data) async{
    return writeCharacteristic(
        smartMeters.elementAt(index).id,
        smartMetersServices.elementAt(index).first.serviceId,
        smartMeterWifiNameUuid,
        data
    );
  }

  Future<bool> writeWifiPass(int index, String data) async{
    return writeCharacteristic(
      smartMeters.elementAt(index).id,
      smartMetersServices.elementAt(index).first.serviceId,
      smartMeterWifiPassUuid,
      data
    );
  }

  //Reads "data" to a characteristic,
  //"deviceId" is the device's MAC address.
  //Returns the data in a utf8 String, or null on error
  Future<String?> readFromCharacteristic(String deviceId, Uuid serviceUUID, Uuid characteristicUUID,) async{
    String? response;

    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUUID,
      characteristicId: characteristicUUID,
    );

    try {
      List<int> bytes = await bluetooth.readCharacteristic(characteristic);
      return utf8.decode(bytes);
    }
    catch(e){
      if (kDebugMode) {
        print("Error reading wifi password from Bluetooth\n");
        print(e);
      }
    }

    return response;
  }

  //Writes "data" to a characteristic,
  //"deviceId" is the device's MAC address.
  //Reruns if the write was a success.
  Future<bool> writeCharacteristic(String deviceId, Uuid serviceUUID, Uuid characteristicUUID, String data) async{
    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: serviceUUID,
      characteristicId: characteristicUUID,
    );

    try {
      await bluetooth.writeCharacteristicWithResponse(characteristic, value: utf8.encode(data));
      return true;
    }
    catch(e){
      if (kDebugMode) {
        print("Error: Error writing characteristic with id: $deviceId\n");
        print(e);
      }
      return false;
    }
  }
}

class SmartMeterCharacteristics{
  final DiscoveredCharacteristic token;
  final DiscoveredCharacteristic wifiName;
  final DiscoveredCharacteristic wifiPass;

  SmartMeterCharacteristics(this.token, this.wifiName, this.wifiPass);
}

class DiscoveryResultHandler{
  final List<DiscoveredDevice> discoveredDevices;
  final void Function(bool, List<String>) onScanCompleted;
  final BluetoothHelper bluetoothHelper;

  DiscoveryResultHandler(this.discoveredDevices, this.onScanCompleted, this.bluetoothHelper);

  void onDeviceDiscovered(DiscoveredDevice device){
    discoveredDevices.add(device);
  }

  void onDiscoveryError(Object e, StackTrace trace){
    if (kDebugMode) {
      print("Error: Error discovering bluetooth devices:");
      print(e.toString());
      print(trace.toString());
    }
    onScanCompleted(false, List.empty());
  }

  void onDiscoveryCompleted() async {
    onScanCompleted(true, await bluetoothHelper.analiseDiscoveredDevices());
  }
}
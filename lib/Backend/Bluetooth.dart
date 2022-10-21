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

    Future.delayed(Duration(seconds: 5), () async {
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
    String? response;

    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: smartMeters.elementAt(index).id,
      serviceId: smartMetersServices.elementAt(index).first.serviceId,
      characteristicId: smartMeterTokenUuid,
    );

    try {
      List<int> bytes = await bluetooth.readCharacteristic(characteristic);
      return utf8.decode(bytes);
    }
    catch(e){
      if (kDebugMode) {
        print("Error reading token from Bluetooth\n");
        print(e);
      }
    }

    return response;
  }

  Future<String?> readWifiName(int index) async{
    String? response;

    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: smartMeters.elementAt(index).id,
      serviceId: smartMetersServices.elementAt(index).first.serviceId,
      characteristicId: smartMeterWifiNameUuid,
    );

    try {
      List<int> bytes = await bluetooth.readCharacteristic(characteristic);
      return utf8.decode(bytes);
    }
    catch(e){
      if (kDebugMode) {
        print("Error reading wifi name from Bluetooth\n");
        print(e);
      }
    }

    return response;
  }

  Future<String?> readWifiPass(int index) async{
    String? response;

    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: smartMeters.elementAt(index).id,
      serviceId: smartMetersServices.elementAt(index).first.serviceId,
      characteristicId: smartMeterWifiPassUuid,
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

  Future<bool> writeToken(int index, String data) async{
    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: smartMeters.elementAt(index).id,
      serviceId: smartMetersServices.elementAt(index).first.serviceId,
      characteristicId: smartMeterWifiPassUuid,
    );

    try {
      await bluetooth.writeCharacteristicWithResponse(characteristic, value: utf8.encode(data));
      return true;
    }
    catch(e){
      if (kDebugMode) {
        print("Error writing token to Bluetooth\n");
        print(e);
      }
      return false;
    }
  }

  Future<bool> writeWifiName(int index, String data) async{
    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: smartMeters.elementAt(index).id,
      serviceId: smartMetersServices.elementAt(index).first.serviceId,
      characteristicId: smartMeterWifiNameUuid,
    );

    try {
      await bluetooth.writeCharacteristicWithResponse(characteristic, value: utf8.encode(data));
      return true;
    }
    catch(e){
      if (kDebugMode) {
        print("Error writing wifi name to Bluetooth\n");
        print(e);
      }
      return false;
    }
  }

  Future<bool> writeWifiPass(int index, String data) async{
    //This is necessary for reading the characteristic
    final characteristic = QualifiedCharacteristic(
      deviceId: smartMeters.elementAt(index).id,
      serviceId: smartMetersServices.elementAt(index).first.serviceId,
      characteristicId: smartMeterWifiPassUuid,
    );

    try {
      await bluetooth.writeCharacteristicWithResponse(characteristic, value: utf8.encode(data));
      return true;
    }
    catch(e){
      if (kDebugMode) {
        print("Error writing wifi password to Bluetooth\n");
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
    print("Error: Error discovering bluetooth devices:");
    print(e.toString());
    print(trace.toString());
    onScanCompleted(false, List.empty());
  }

  void onDiscoveryCompleted() async {
    onScanCompleted(true, ['Smart Meter']);//await bluetoothHelper.analiseDiscoveredDevices());//TODO: Debug
  }
}
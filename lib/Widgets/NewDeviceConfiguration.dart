import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/Dialogs/ListPickerDialog.dart';
import 'package:smart_meter/Dialogs/ProgressDialog.dart';
import 'package:smart_meter/Dialogs/TextFieldDialog.dart';
import 'package:smart_meter/Dialogs/WifiNamePassDialog.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../Backend/Bluetooth.dart';
import '../Backend/JsonClasses.dart';
import '../main.dart';


//This is the New Device Screen definition, it uses several pages
//for asking the user information about the device and it's
//configuration
class NewDeviceConfiguration extends StatefulWidget{
  BackendComm backend;
  Hogar hogar;
  NewDeviceConfiguration(this.backend, this.hogar,{Key? key}) : super(key: key);

  @override
  State<NewDeviceConfiguration> createState() =>
      NewDeviceConfigurationState();
}

//This State holds all the information from the user input and the state
//of the animations
class NewDeviceConfigurationState extends State<NewDeviceConfiguration>{
  BluetoothHelper bluetooth = BluetoothHelper();

  static const int BLUETOOTH_SEARCH_SCREEN = 0;
  static const int WIFI_CONFIGURATION_SCREEN = 1;
  static const int NAME_CONFIGURATION_SCREEN = 2;

  int actualScreenID = BLUETOOTH_SEARCH_SCREEN;
  bool reverse = false; //If the animation should be in reverse
  late Widget actualScreen;

  String? wifiName;
  String? wifiPass;
  String? token;
  String? name;
  int? bluetoothListIndex;

  NewDeviceConfigurationState(){
    actualScreen = BluetoothSearchScreen(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurar Nuevo Smart Meter"),
      ),

      body: Column(
        children: [
          //This Expanded will hold each of the pages
          Expanded(
            child: PageTransitionSwitcher(
              //This child holds the next screen to be transitioned
              child: actualScreen,
              duration: const Duration(milliseconds: 300),
              reverse: reverse,
              transitionBuilder: (child, animation, secondaryAnimation,){
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child
                );
              },
            )
          ),

          //This padding will hold the buttons used for transit to other screen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Back button
                ElevatedButton(
                  onPressed: () => jumpToBackScreen(context),
                  child: const Text("Atrás"),
                ),
                //Next button
                ElevatedButton(
                  onPressed: () => jumpToNextScreen(context),
                  child: const Text("Siguiente"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void jumpToNextScreen(BuildContext context) async {
    reverse = false;
    switch(actualScreenID){
      case BLUETOOTH_SEARCH_SCREEN:
        //If the device has been found and connected
        if(bluetoothListIndex != null){
          //Jump to next screen
          setState(() {
            actualScreenID = WIFI_CONFIGURATION_SCREEN;
            actualScreen = WifiConfigurationScreen(this);
          });
        }
        else{
          showError(context, "No hay ningún dispositivo seleccionado");
        }
      break;

      case WIFI_CONFIGURATION_SCREEN:
        if(wifiName != null && wifiPass != null){
          //Jump to next screen
          setState(() {
            actualScreenID = NAME_CONFIGURATION_SCREEN;
            actualScreen = NameConfigurationScreen(this);
          });
        }
        else{
          showError(context, "No se ha seleccionado la red WiFi");
        }
      break;

      case NAME_CONFIGURATION_SCREEN:
        if(name != null){
          //Configure device
          ProgressDialog progress = const ProgressDialog("Obteniedo nuevas claves");
          progress.show(context);

          //Get the device token
          String? token = await widget.backend.sendNewDevice(name!, widget.hogar);

          if(mounted) {
            progress.dismiss(context);

            //If there has not been any error
            if (token != null) {
              progress = const ProgressDialog("Configurando dispositivo");
              progress.show(context);

              //Configure the device through bluetooth
              bool allOk = await bluetooth.writeWifiName(bluetoothListIndex!, wifiName!);
              allOk &= await bluetooth.writeWifiPass(bluetoothListIndex!, wifiPass!);
              allOk &= await bluetooth.writeToken(bluetoothListIndex!, token);

              if(mounted){
                progress.dismiss(context);
                if(allOk) {
                  showError(context, "Dispositivo configurado correctamente", onDismiss: (){
                    if(mounted){
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoot.homeDashboardRoute,
                        (route) => false
                      );
                    }
                  });
                }
              }
            }
            else{
              showError(context,
                  "Error: No ha sido posible obtener las claves del nuevo dispositivo\n" +
                  "Comprueba tu conexión a internet e intentalo de nuevo"
              );
            }
          }
        }
        else{
          showError(context, "No se ha seleccionado la red WiFi");
        }
      break;
    }
  }

  void jumpToBackScreen(BuildContext context){
    reverse = true;
    switch(actualScreenID){
      case BLUETOOTH_SEARCH_SCREEN:
        //Close screen
        Navigator.pop(context);
      break;
        
      case WIFI_CONFIGURATION_SCREEN:
        //Jump to previous screen
        setState(() {
          actualScreenID = BLUETOOTH_SEARCH_SCREEN;
          actualScreen = BluetoothSearchScreen(this);
        });
      break;

      case NAME_CONFIGURATION_SCREEN:
        //Jump to previous screen
        setState(() {
          actualScreenID = WIFI_CONFIGURATION_SCREEN;
          actualScreen = WifiConfigurationScreen(this);
        });
      break;
    }
  }

  void showError(BuildContext context, String message, {void Function()? onDismiss}){
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(label: 'Ocultar',
        onPressed: onDismiss == null ? scaffold.hideCurrentSnackBar : (){
          onDismiss;
          scaffold.hideCurrentSnackBar();
        }
      ),
    ));
  }
}

class BluetoothSearchScreen extends StatefulWidget{
  final NewDeviceConfigurationState deviceState;

  const BluetoothSearchScreen(this.deviceState, {Key? key});

  @override
  State<BluetoothSearchScreen> createState() => BluetoothSearchScreenState();
}

class BluetoothSearchScreenState extends State<BluetoothSearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25.0),
            child: ElevatedButton(
              onPressed: () => bluetoothScan(context), child: const Text("Escanear Dispositivos Bluetooth")
            ),
          ),
          Container(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Text(
                  "Nombre Del Dispoitivo",
                  textScaleFactor: 1.25,
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget.deviceState.name != null ? widget.deviceState.name.toString() : "",
                    textScaleFactor: 1.25,
                  )
                ),
              ],
            )
          )
        ],
      )
    );
  }

  void bluetoothScan(BuildContext context) async {
    ProgressDialog progress = ProgressDialog("Buscando Smart Meters");
    progress.show(context);

    widget.deviceState.bluetoothListIndex = 0;
    widget.deviceState.name = null;

    //Scan for devices
    widget.deviceState.bluetooth.scanForSmartMeters((ok, names){
      if(mounted){
        progress.dismiss(context);
        if(ok){
          //If a devices has been detected
          if(!names.isEmpty) {
            //Ask the user for select the device
            ListPickerDialog(
                "Selecciona el dispositivo que que se va a configurar",
                "Sececcionar",
                "Cancelar",
                (selected) async {
                  ProgressDialog progress = ProgressDialog("Conectando");
                  progress.show(context);

                  widget.deviceState.bluetooth.connect(selected, (ok) {
                    progress.dismiss(context);
                    if(ok) {
                      setState(() {
                        widget.deviceState.bluetoothListIndex = selected;
                        widget.deviceState.name = names[selected];
                      });
                    }
                    else{
                      widget.deviceState.showError(context, "Error: No se ha podido connectar con el dispositivo");
                    }
                  });
                },
                () {}, //ignore on cancel
                names
            ).show(context);
          }
          else{
            widget.deviceState.showError(context, "No se han encontrado dispositivos");
            setState(() {
              widget.deviceState.bluetoothListIndex = 0;
              widget.deviceState.name = null;
            });
          }
        }
        else{
          widget.deviceState.showError(context,
              "Error: Comprueba que tienes el bluetooth hablilitado" +
              " y has concedido permiso a esta aplicación");
          setState(() {
            widget.deviceState.bluetoothListIndex = 0;
            widget.deviceState.name = null;
          });
        }
      }
    });
  }
}

class WifiConfigurationScreen extends StatefulWidget{
  final NewDeviceConfigurationState deviceState;
  
  const WifiConfigurationScreen(this.deviceState, {super.key});

  @override
  State<WifiConfigurationScreen> createState() => _WifiConfigurationScreenState();
}

class _WifiConfigurationScreenState extends State<WifiConfigurationScreen> {
  String? wifiName;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25.0),
            child: ElevatedButton(
                onPressed: () => getWifiName(context),
                child: const Text("Conectar a la red WiFi")
            ),
          ),
          Container(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Text(
                    "Nombre De La Red WiFi",
                    textScaleFactor: 1.25,
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      widget.deviceState.wifiName != null ? widget.deviceState.wifiName.toString() : "",
                      textScaleFactor: 1.25,
                    )
                ),
              ],
            )
          ),
          Container(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Text(
                  "Contraseña De La Red WiFi",
                  textScaleFactor: 1.25,
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget.deviceState.wifiPass != null ? widget.deviceState.wifiPass.toString().replaceAll(RegExp("."), "*") : "",
                    textScaleFactor: 1.25,
                  )
                ),
              ],
            )
          ),
        ],
      )
    );
  }

  void getWifiName(BuildContext context) async {
    List<String> wifiNames = List.empty(growable: true);
    ProgressDialog progressDialog = ProgressDialog("Escaneando redes Wifi");

    WiFiScan wifi = WiFiScan.instance;

    wifi.onScannedResultsAvailable.listen(
      (accessPoints) {
        for(WiFiAccessPoint accessPoint in accessPoints){
          wifiNames.add(accessPoint.ssid);
        }
      },
      onError: (error, trace) {
        progressDialog.dismiss(context);
        widget.deviceState.showError(context, "Error: Error buscando puntos de acceso");
        print(error.toString());
        print(trace.toString());
      },
    );

    if(await wifi.canStartScan(askPermissions: true) == CanStartScan.yes){
      Future.delayed(Duration(seconds: 5, ),(){
        if (mounted) {
          progressDialog.dismiss(context);
          if(!wifiNames.isEmpty){
            ListPickerDialog(
              "Selecciona la red wifi para el Smart Meter",
              "Seleccionar",
              "Cancelar",
                  (i) {
                wifiName = wifiNames[i];
                if(mounted) {
                  if (wifiName != null) {
                    TextFieldDialog(
                        "Contraseña de " + wifiName!,
                        "Establecer",
                        "Cancelar",
                        onWifiPasswordProvided,
                            () {} //Ignore on cancelar
                    ).show(context);
                  }
                  else {
                    widget.deviceState.showError(context, "Error: El punto de acceso no es válido");
                  }
                }
              },
                  () => progressDialog.dismiss(context),
              wifiNames
            ).show(context);
          }
          else{
            widget.deviceState.showError(context, "No se han encontrado puntos de acceso");
          }
        }
      });
      bool ok = await wifi.startScan();
      if(ok){
        progressDialog.show(context);
      }
      else{
        widget.deviceState.showError(context, "Error: Error buscando puntos de acceso");
      }
    }
    //Manually introduce the data
    else{
      WifiNamePassDialog dialog = WifiNamePassDialog(
          "Introducir datos maualmente",
          "Enviar",
          "Cancelar",
          (name, pass) {
            wifiName = name;
            onWifiPasswordProvided(pass);
          },
          () { }//Ignore onCancel
      );

      widget.deviceState.showError(context, "Error: Tu sistema no permite buscar puntos de acceso de forma automatica");
      dialog.show(context);
    }
  }

  void onWifiPasswordProvided(String password){
    setState(() {
      widget.deviceState.wifiName = wifiName;
      widget.deviceState.wifiPass = password;
    });
  }
}

class NameConfigurationScreen extends StatefulWidget{
  final NewDeviceConfigurationState deviceState;

  const NameConfigurationScreen(this.deviceState, {Key? key});

  @override
  State<NameConfigurationScreen> createState() => NameConfigurationScreenState();
}

class NameConfigurationScreenState extends State<NameConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Text(
                  "Nombre del dispositivo",
                  textScaleFactor: 1.25,
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget.deviceState.name != null ? widget.deviceState.name.toString() : "",
                    textScaleFactor: 1.25,
                  )
                ),
              ],
            )
          ),
          Container(
            padding: const EdgeInsets.all(25.0),
            child: ElevatedButton(
                onPressed: () => selectName(context),
                child: const Text("Cambiar nombre")
            ),
          ),
        ],
      )
    );
  }

  void selectName(BuildContext context){
    TextFieldDialog(
      "Nombre",
      "Establecer",
      "Cancelar",
      onNameSet,
      (){}
    ).show(context);
  }

  void onNameSet(String name){
    if(mounted){
      setState(() {
        widget.deviceState.name = name;
      });
    }
  }
}
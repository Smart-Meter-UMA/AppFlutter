import 'package:flutter/material.dart';
import 'package:smart_meter/Dialogs/ListPickerDialog.dart';
import 'package:smart_meter/Dialogs/ProgressDialog.dart';

import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/Widgets/NewDeviceConfiguration.dart';
import 'package:smart_meter/main.dart';

import '../Backend/JsonClasses.dart';
import 'DashboardItem.dart';

class Dashboard extends StatefulWidget {
  BackendComm backend;

  Dashboard(this.backend, {Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  List<Hogar>? hogares;
  List<Dispositivo>? dispositivosWithoutStadistics;
  List<Dispositivo>? dispositivosWithStadistics;
  late Future<ListView> futureDashboarItems;

  @override
  void initState(){
    super.initState();
    futureDashboarItems = getDashboardItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hogares de ${widget.backend.getUsername()}"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppRoot.appMainColor,
              ),
              child: Text(
                "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Crear Hogar"),
                //TODO: onTap()
            ),
            ListTile(
              leading: Icon(Icons.app_blocking),
              title: Text("Eliminar Hogar"),
              //TODO: onTap()
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () => signOut()
            ),
          ]
        ),
      ),
      body: Center(
        child: FutureBuilder<ListView>(
          future: futureDashboarItems,
          builder: (context, snapshot){
            if(snapshot.hasData){
              return snapshot.data!;
            }
            else if(snapshot.hasError){
              return const Text("Error: Error obteniendo datos");
            }

            return const CircularProgressIndicator();
          }
        )
      )
    );
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

  void signOut() async {
    ProgressDialog progressDialog = const ProgressDialog("Cerrando sesión");
    progressDialog.show(context);

    await widget.backend.googleSignOut();

    if(mounted){
      progressDialog.dismiss(context);
    }
  }

  Future<ListView> getDashboardItems() async {
    List<Hogar>? hogares = this.hogares;
    List<Dispositivo>? dispositivosWithoutStadistics = this.dispositivosWithoutStadistics;
    List<Dispositivo>? dispositivosWithStadistics = this.dispositivosWithStadistics;

    //Get 'hogares' if they are not stored here
    if(hogares == null){
      hogares = await widget.backend.getHogares();
      if(hogares == null){
        throw("Error: Backend error fetching 'hogares'");
      }
    }
    //Get all 'dispositivos' from each of the 'hogares' if they are not stored here
    if(dispositivosWithoutStadistics == null){
      List<Dispositivo> tempDispositivos = List.empty(growable: true);
      for(Hogar hogar in hogares){
        List<Dispositivo>? returndedDispositivos = await widget.backend.getDispositivosFromHogar(hogar);

        if(returndedDispositivos != null){
          tempDispositivos.addAll(returndedDispositivos);
        }
        else{
          throw("Error: Backend error fetching 'dispositivos' from 'hogar'");
        }
      }

      dispositivosWithoutStadistics = tempDispositivos;
    }
    //Get all 'stadistics' from 'dispositivos' if they are not stored here
    if(dispositivosWithStadistics == null){
      List<Dispositivo> tempDispositivos = List.empty(growable: true);

      for(Dispositivo dispositivo in dispositivosWithoutStadistics){
        Dispositivo? returnedDispositivo = await widget.backend.getDispositivoFromID(dispositivo);

        if(returnedDispositivo != null){
          tempDispositivos.add(returnedDispositivo);
        }
        else{
          throw "Error: Backend error fetching 'dispositivo' with statistics from the 'dispositivo'";
        }
      }
    }
    //Store the results
    if(this.hogares == null || this.dispositivosWithoutStadistics == null || this.dispositivosWithStadistics == null) {
      this.hogares = hogares;
      this.dispositivosWithoutStadistics = dispositivosWithoutStadistics;
      this.dispositivosWithStadistics = dispositivosWithStadistics;
    }

    //Get the power and costs for every hogar
    List<List<double>> powersAndCosts = getHoagresTodayPowerAndCosts();

    //If there are 'hogares'
    if(hogares.isNotEmpty) {
      //Generate the ListView
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List<DashboardItem>.generate(hogares.length, (i) =>
            DashboardItem(
                hogares![i],
                powersAndCosts[0][i],
                powersAndCosts[1][i],
                this.dispositivosWithStadistics!
            )
        ),
      );
    }
    else{
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text("No se han encontrado hogares")
        ]
      );
    }
  }

  List<List<double>> getHoagresTodayPowerAndCosts(){
    List<List<double>> powersAndCosts = [
      List.generate(hogares!.length, (index) => 0),
      List.generate(hogares!.length, (index) => 0),
    ];
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for(int i = 0; i < hogares!.length; i++){
      for(Dispositivo dispositivo in dispositivosWithStadistics!){
        if(dispositivo.hogar!.id == hogares![i].id){
          DateTime dayFromFechaHoy = DateTime(
              dispositivo.estadistica!.fechaHoy.year,
              dispositivo.estadistica!.fechaHoy.month,
              dispositivo.estadistica!.fechaHoy.day
          );
          if(dayFromFechaHoy == today) {
            powersAndCosts[0][i] += dispositivo.estadistica!.consumidoHoy;
            powersAndCosts[1][i] += dispositivo.estadistica!.sumaDiaDinero;
          }
        }
      }
    }

    return powersAndCosts;
  }

  void onNewDeviceHogarSelected(int index){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewDeviceConfiguration(widget.backend, hogares![index]))
    );
  }
}
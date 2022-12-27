import 'package:flutter/material.dart';
import 'package:smart_meter/Dialogs/ListPickerDialog.dart';
import 'package:smart_meter/Dialogs/ProgressDialog.dart';

import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/main.dart';

import '../Backend/JsonClasses.dart';
import '../Dialogs/HogarDataDialog.dart';
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
  late Future<ListView> futureDashboardItems;

  @override
  void initState(){
    super.initState();
    futureDashboardItems = getDashboardItems();
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
              onTap: (){
                HogarDataDialog(
                  "Datos del nuevo hogar",
                  "Enviar",
                  "Cancelar",
                  onNewHogarUserInput,
                  (){} //Ignore on cancel
                ).show(context);
              }
            ),
            ListTile(
              leading: const Icon(Icons.app_blocking),
              title: const Text("Eliminar Hogar"),
                onTap: () {
                  if (hogares != null && hogares!.isNotEmpty) {
                    ListPickerDialog(
                      "Selecciona el hogar a eliminar",
                      "Eliminar",
                      "Cancelar",
                      onDeleteHogarUserInput,
                      () {}, //Ignore on cancel
                      List.generate(hogares!.length, (i) => hogares![i].nombre)
                    ).show(context);
                  }
                  else{
                    showError(context, "No hay datos sobre ningún hogar");
                  }
                }
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
          future: futureDashboardItems,
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

  void onNewHogarUserInput(Hogar hogar) async {
    ProgressDialog progress = const ProgressDialog("Enviando");

    progress.show(context);
    bool ok = await widget.backend.sendNewHogar(hogar);

    if(mounted){
      progress.dismiss(context);
      if(ok){
        showError(context, 'Nuevo hogar "${hogar.nombre}" creado');
        forceDataUpdate();
      }
      else{
        showError(context, "Error creando nuevo hogar");
      }
    }
  }

  void onDeleteHogarUserInput(int index) async {
    ProgressDialog progress = const ProgressDialog("Eliminando");

    progress.show(context);
    bool ok = await widget.backend.deleteHogar(hogares![index]);

    if(mounted){
      progress.dismiss(context);
      if(ok){
        //showError(context, 'Hogar "${hogares![index].nombre}" eliminado');
        forceDataUpdate();
      }
      else{
        showError(context, "Error eliminando nuevo hogar");
      }
    }
  }

  void forceDataUpdate(){
    setState(() {
      hogares = null;
      dispositivosWithoutStadistics = null;
      dispositivosWithStadistics = null;
      futureDashboardItems = getDashboardItems();
    });
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

      dispositivosWithStadistics = tempDispositivos;
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
            getDispositivosFromHogar(hogares[i], this.dispositivosWithStadistics!),
            widget.backend
          )
        ),
      );
    }
    else{
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Center(
            child: Text(
              "No se han encontrado hogares",
              textScaleFactor: 1.5,
            )
        )
        ]
      );
    }
  }

  static List<Dispositivo> getDispositivosFromHogar(Hogar hogar, List<Dispositivo> candidates){
    List<Dispositivo> foundList = List.empty(growable: true);

    for(Dispositivo candidate in candidates){
      if(candidate.hogar!.id == hogar.id){
        foundList.add(candidate);
      }
    }

    return foundList;
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
}
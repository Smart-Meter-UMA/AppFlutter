import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/Backend/JsonClasses.dart';
import 'package:smart_meter/Dialogs/ListPickerDialog.dart';
import 'package:smart_meter/Dialogs/ProgressDialog.dart';
import 'package:smart_meter/Widgets/DashboardHogarItem.dart';
import 'package:smart_meter/Widgets/NewDeviceConfiguration.dart';
import 'package:smart_meter/main.dart';

class DashboardHogar extends StatefulWidget {
  final BackendComm backend;
  final Hogar hogar;
  final List<Dispositivo> dispositivos;

  DashboardHogar(this.backend, this.hogar, this.dispositivos, {Key? key}){}

  @override
  State<DashboardHogar> createState() => DashboardHogarState();
}

class DashboardHogarState extends State<DashboardHogar>{
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
        title: Text("Hogar: " + widget.hogar.nombre),
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
              leading: const Icon(Icons.network_wifi),
              title: const Text("Configurar Nuevo Dispositivo"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NewDeviceConfiguration(widget.backend, widget.hogar)
                  )
                );
              }
            ),
            ListTile(
              leading: Icon(Icons.account_tree),
              title: Text("Modificar Dspositivo"),
              //TODO: onTap()
            ),
            ListTile(
              leading: Icon(Icons.app_blocking),
              title: Text("Eliminar Dispositivo"),
              //TODO: onTap()
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () => signOut()
            ),
          ],
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
      ),
    );
  }

  Future<ListView> getDashboardItems() async {
    List<List<Medida>> medidasList = List.empty(growable: true);
    List<Medida?> lastMedidias = List.empty(growable: true);

    for(Dispositivo dispositivo in widget.dispositivos){
      medidasList.add(await getTodayMedidas(dispositivo));
      lastMedidias.add(await widget.backend.getLastMedida(dispositivo));
    }

    if(widget.dispositivos.isNotEmpty){
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List<DashboardHogarItem>.generate(widget.dispositivos.length, (i) =>
            DashboardHogarItem(
                widget.dispositivos[i],
                medidasList[i],
                medidasList[i].last
            )
        ),
      );
    }
    else{
      return ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text("No se han encontrado dispositivos")
          ]
      );
    }
  }

  Future<List<Medida>> getTodayMedidas(Dispositivo dispositivo) async {
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<Medida>? medidas = await widget.backend.getMedidas(dispositivo, todayStart, todayEnd);

    if(medidas != null){
      return medidas;
    }
    else {
      if(mounted) {
        showError(context, "Error: Error obteniendo el histórico");
      }
      throw "Error: Backend error fetching 'medidas' from the 'dispositivo'";
    }
  }

  void signOut() async {
    ProgressDialog progressDialog = const ProgressDialog("Cerrando sesión");
    progressDialog.show(context);

    await widget.backend.googleSignOut();

    if(mounted){
      progressDialog.dismiss(context);
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
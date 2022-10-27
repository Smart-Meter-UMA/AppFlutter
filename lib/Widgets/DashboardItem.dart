import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/Widgets/DashboardHogar.dart';
import 'package:smart_meter/main.dart';

import '../Backend/JsonClasses.dart';

class DashboardItem extends StatefulWidget{
  final Hogar hogar;
  final double todayPower;
  final double todayCost;
  final List<Dispositivo> dispositivosWithStadistics;
  final BackendComm backend;

  const DashboardItem(this.hogar, this.todayPower, this.todayCost,
      this.dispositivosWithStadistics, this.backend, {Key? key}) : super(key: key);

  @override
  State<DashboardItem> createState() => DashboardItemState();
}

class DashboardItemState extends State<DashboardItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: InkWell(
        onTap: (){
          Navigator.push(
              context, MaterialPageRoute(
              builder: (context) {
                return DashboardHogar(
                    widget.backend,
                    widget.hogar,
                    widget.dispositivosWithStadistics
                );
              }
            )
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppRoot.appMainColor,
                //border: Border.all(),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20)
                )
              ),
              child: Text(
                widget.hogar.nombre,
                textScaleFactor: 2,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child :Column(
                children: [
                  const Text(
                      "Consumo de hoy",
                      textScaleFactor: 1.25,
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text(
                    widget.todayPower.toStringAsFixed(2) + "KWh",
                    textScaleFactor: 1.5,
                    //style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child :Column(
                children: [
                  const Text(
                      "Costo de hoy",
                      textScaleFactor: 1.25,
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text(
                    widget.todayCost.toStringAsFixed(2) + '\u{20AC}',
                    textScaleFactor: 1.5,
                    //style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ],
        )
      )
    );
  }
}
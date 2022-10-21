import 'package:flutter/material.dart';

import '../Backend/JsonClasses.dart';

class DashboardItem extends StatefulWidget{
  final Hogar hogar;
  final double todayPower;
  final double todayCost;
  final List<Dispositivo> dispositivosWithStadistics;

  const DashboardItem(this.hogar, this.todayPower, this.todayCost,
      this.dispositivosWithStadistics, {Key? key}) : super(key: key);

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
        //TODO: Implement onTap: ,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
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
                    widget.todayPower.toString(),
                    textScaleFactor: 2,
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
                    widget.todayCost.toString(),
                    textScaleFactor: 2,
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
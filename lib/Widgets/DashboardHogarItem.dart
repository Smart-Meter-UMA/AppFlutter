import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../Backend/JsonClasses.dart';

class DashboardHogarItem extends StatefulWidget{
  final Dispositivo dispositivo;
  final List<Medida> medidas;
  final Medida? lastMedida;

  const DashboardHogarItem(this.dispositivo, this.medidas,
    this.lastMedida, {Key? key}) : super(key: key);

  @override
  State<DashboardHogarItem> createState() => DashboardHogarItemState();
}

class DashboardHogarItemState extends State<DashboardHogarItem> {
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
                widget.dispositivo.nombre,
                textScaleFactor: 2,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child :Column(
                children: [
                  const Text(
                      "Potencia Actual",
                      textScaleFactor: 1.25,
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text(
                    widget.lastMedida != null ? widget.lastMedida!.kw.toStringAsFixed(2) + " KW" : "Sin datos" ,
                    textScaleFactor: 1.5,
                    //style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child :Column(
                children: [
                  const Text(
                    "Actualizado",
                    textScaleFactor: 1.25,
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text(
                    widget.lastMedida != null ? getLastUpdatedToText(widget.lastMedida!.fecha) : "Sin datos",
                    textScaleFactor: 1.5,
                    //style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            SfCartesianChart(
              title: ChartTitle(
                text: "Histórico",
                textStyle:
                const TextStyle(fontWeight: FontWeight.bold)
              ),
              legend: Legend(isVisible: false),
              primaryXAxis: DateTimeAxis(),
              primaryYAxis: NumericAxis(),
              series: <ChartSeries<Medida, DateTime>>[
                LineSeries<Medida, DateTime>(
                  dataSource: widget.medidas,
                  xValueMapper: (Medida medida, _) => medida.fecha,
                  yValueMapper: (Medida medida, _) => medida.kw,
                  name: 'Potencia',
                  dataLabelSettings: const DataLabelSettings(isVisible: false)
                )
              ]
            )
          ],
        )
      )
    );
  }

  String getLastUpdatedToText(DateTime date){
    Duration difference = DateTime.now().difference(date);

    if(difference.inDays > 0){
      return "Hace " + difference.inDays.toString() + " dias";
    }
    else if(difference.inHours > 0){
      return "Hace " + difference.inHours.toString() + " horas";
    }
    else if(difference.inMinutes > 0){
      return "Hace " + difference.inMinutes.toString() + " minutos";
    }
    else{
      return "Ahora";
    }
  }
}
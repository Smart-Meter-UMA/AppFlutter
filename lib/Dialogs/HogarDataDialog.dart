import 'dart:core';

import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/JsonClasses.dart';

class HogarDataDialog extends StatefulWidget{
  final String title;
  final String okButtonText;
  final String cancelButtonText;
  final void Function(Hogar) onOk;
  final void Function() onCancel;

  const HogarDataDialog(this.title, this.okButtonText, this.cancelButtonText,
      this.onOk, this.onCancel, {super.key});

  @override
  State<HogarDataDialog> createState() => HogarDataDialogState();

  void show(BuildContext context){
    showDialog(
      context: context,
      builder:(BuildContext context){
        return this;
      },
    );
  }

  void dismissDialog(BuildContext context){
    Navigator.pop(context);
  }
}

class HogarDataDialogState extends State<HogarDataDialog>{
  TextEditingController nameController = TextEditingController();
  TextEditingController potenciaContratadaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text(widget.cancelButtonText),
          onPressed: (){
            Navigator.pop(context);
            widget.onCancel();
          }
        ),
        ElevatedButton(
          child: Text(widget.okButtonText),
          onPressed: (){
            if(nameController.text != "" && potenciaContratadaController.text != "") {
              int? potenciaContratada = int.tryParse(potenciaContratadaController.text);

              if(potenciaContratada != null) {
                Navigator.pop(context);
                widget.onOk(
                  Hogar(
                    id: 0,
                    nombre: nameController.text,
                    potencia_contratada: potenciaContratada
                  )
                );
              }
            }
          }
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              width: double.maxFinite,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Nombre"
                ),
                controller: nameController,
                enableSuggestions: false,
                keyboardType: TextInputType.name,
              )
            ),
            Container(
              padding: const EdgeInsets.all(5),
              width: double.maxFinite,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Potencia contratada"
                ),
                controller: potenciaContratadaController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(),
              )
            ),
          ]
        )
      )
    );
  }
}

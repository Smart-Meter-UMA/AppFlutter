import 'dart:core';

import 'package:flutter/material.dart';

class WifiNamePassDialog extends StatefulWidget{
  final String title;
  final String okButtonText;
  final String cancelButtonText;
  final void Function(String, String) onOk;
  final void Function() onCancel;

  const WifiNamePassDialog(this.title, this.okButtonText, this.cancelButtonText,
      this.onOk, this.onCancel, {super.key});

  @override
  State<WifiNamePassDialog> createState() => WifiNamePassDialogState();

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

class WifiNamePassDialogState extends State<WifiNamePassDialog>{
  TextEditingController nameController = TextEditingController();
  TextEditingController passController = TextEditingController();

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
              if(nameController.text != "" && passController.text != "") {

                Navigator.pop(context);
                widget.onOk(nameController.text, passController.text);
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
                    hintText: "Nombre de la red WiFi"
                ),
                controller: nameController,
                enableSuggestions: false,
              )
            ),
            Container(
              padding: const EdgeInsets.all(5),
              width: double.maxFinite,
              child: TextField(
                decoration: const InputDecoration(
                    hintText: "Contraseña de la red WiFi"
                ),
                controller: passController,
                enableSuggestions: false,
              )
            ),
          ]
        )
      )
    );
  }
}


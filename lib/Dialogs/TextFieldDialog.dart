import 'dart:core';

import 'package:flutter/material.dart';

class TextFieldDialog extends StatefulWidget{
  final String title;
  final String okButtonText;
  final String cancelButtonText;
  final void Function(String) onOk;
  final void Function() onCancel;

  const TextFieldDialog(this.title, this.okButtonText, this.cancelButtonText,
      this.onOk, this.onCancel, {super.key});

  @override
  State<TextFieldDialog> createState() => TextFieldDialogState();

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

class TextFieldDialogState extends State<TextFieldDialog>{
  TextEditingController textController = TextEditingController();

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
              if(textController.text != "") {
                Navigator.pop(context);
                widget.onOk(textController.text);
              }
            }
        ),
      ],
      content: SingleChildScrollView(
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: textController,
              )
            )
          ]
        )
      )
    );
  }
}


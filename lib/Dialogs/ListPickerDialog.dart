import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListPickerDialog extends StatefulWidget{
  final String title;
  final String okButtonText;
  final String cancelButtonText;
  final void Function(int) onOk;
  final void Function() onCancel;
  final List<String> items;

  const ListPickerDialog(this.title, this.okButtonText, this.cancelButtonText,
      this.onOk, this.onCancel, this.items, {super.key});

  @override
  State<ListPickerDialog> createState() => ListPickerDialogState();

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

class ListPickerDialogState extends State<ListPickerDialog>{
  int actual = 0;

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
          onPressed: () {
            Navigator.pop(context);
            widget.onCancel();
          }
        ),
        ElevatedButton(
          child: Text(widget.okButtonText),
          onPressed: (){
            Navigator.pop(context);
            widget.onOk(actual);
          }
        ),
      ],
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (BuildContext context, int index){
                return RadioListTile(
                  title: Text(widget.items[index]),
                  value: index,
                  groupValue: actual,
                  onChanged: (value){
                    setState(() {
                      actual = index;
                    });
                  }
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}


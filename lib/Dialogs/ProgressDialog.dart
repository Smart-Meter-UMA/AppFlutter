import 'dart:core';
import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget{
  final String text;
  const ProgressDialog(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
              margin: const EdgeInsets.only(left: 7),
              child: Text(text)
          ),
        ],
      ),
    );
  }

  void show(BuildContext context){
    showDialog(
      context: context,
      builder:(BuildContext context){
        return this;
      },
    );
  }

  void dismiss(BuildContext context){
    Navigator.pop(context);
  }
}
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/Dialogs/ProgressDialog.dart';

class LoginScreen extends StatefulWidget {
  final BackendComm backend;

  const LoginScreen(this.backend, {Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>{
  late BackendComm backend;

  @override
  Widget build(BuildContext context) {
    backend = widget.backend;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de sesión'),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(25),
          child: ElevatedButton(
            onPressed: login,
            child: const Text("Iniciar sesión con Google"),
          )
        )
      )
    );
  }

  void login() async{
    ProgressDialog progress = const ProgressDialog("Iniciando sesión");
    progress.show(context);

    if(await backend.googleSignIn()){
      showToast(context, "Inicio de sesión completado");
      progress.dismiss(context);
    }
    else{
      showToast(context, "Error: Error al iniciar sesión");
      progress.dismiss(context);
    }
  }

  showToast(BuildContext context, String text){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text)
      )
    );
  }
}

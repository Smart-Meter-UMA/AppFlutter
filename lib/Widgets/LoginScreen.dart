import 'dart:core';
import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/BackendComm.dart';
import 'package:smart_meter/Dialogs/ProgressDialog.dart';
import 'package:smart_meter/main.dart';

class LoginScreen extends StatefulWidget {
  final BackendComm backend;
  final AppRootState appRoot;

  const LoginScreen(this.backend, this.appRoot, {Key? key}) : super(key: key);

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
          child: OutlinedButton(
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white)),
            onPressed: login,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Image(
                    image: AssetImage("assets/google_logo.png"),
                    height: 35.0,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'Iniciar sesión con Google',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),
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

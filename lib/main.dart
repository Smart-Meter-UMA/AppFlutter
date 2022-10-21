import 'dart:core';
import 'package:flutter/material.dart';
import 'package:smart_meter/Backend/BackendComm.dart';

import 'Backend/JsonClasses.dart';
import 'Widgets/LoginScreen.dart';
import 'Widgets/Dashboard.dart';
import 'Widgets/NewDeviceConfiguration.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppRoot());
}

class AppRoot extends StatefulWidget {
  static const String loginRoute = "/login";
  static const String homeDashboardRoute = "/homeDashboard";
  static const MaterialColor appMainColor = Colors.teal;
  late final BackendComm backend;

  AppRoot({Key? key}) : super(key: key){
    backend = BackendComm();
  }

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  Widget build(BuildContext context) {
    widget.backend.setUserChangeListener(context, this.onLoggedIn, this.onLoggedOut);

    return MaterialApp(
      title: "Smart Meter",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: AppRoot.appMainColor,
        scaffoldBackgroundColor: AppRoot.appMainColor,
      ),
      routes: <String, WidgetBuilder>{
        AppRoot.loginRoute: (context) => LoginScreen(widget.backend),
        AppRoot.homeDashboardRoute: (context) => Dashboard(widget.backend)
      },
      initialRoute: AppRoot.loginRoute
    );
  }

  void onLoggedIn(BuildContext context){
    //Go to Dashboard screen and delete all other
    if(mounted) {
      setState(() {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoot.homeDashboardRoute, (route) => false);
      });
    }
  }

  void onLoggedOut(BuildContext context){
    //Go to login screen and delete all other
    setState(() {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoot.loginRoute, (route) => false);
    });
  }
}
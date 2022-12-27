import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'JsonClasses.dart';

//This class implements all the communications with the backend.
class BackendComm {
  static const String apiUrl = "api-kproject.herokuapp.com";
  static const String dispositivosUrl = "/kproject/dispositivos";
  static const String medidassUrl = "/kproject/medidas";
  static const String hogaresUrl = "/kproject/hogars";
  static const String apiKey = '724046535439-h28ieq17aff119i367el50skelqkdgh4.apps.googleusercontent.com';
  late final GoogleSignIn authenticator;
  String? token;
  String? email;
  String? userName;

  BackendComm(){
    authenticator = GoogleSignIn(
      serverClientId: apiKey,
      scopes: ['email']
    );
  }

  //Adds listeners for Google user changes.
  //WARNING: This callbacks will be executed even if the IU context has changed,
  //use "this.mounted" in the Widget for assuring "this" is the active context.
  void setUserChangeListener(BuildContext context,
      void Function(BuildContext) onLoggedIn,
      void Function(BuildContext) onLoggedOut){
    authenticator.onCurrentUserChanged.listen((account) async {
      if(await authenticator.isSignedIn() && account != null &&
          (account.serverAuthCode != null)){
        token = (await account.authentication).idToken;
        email = account.email;
        userName = account.displayName;
        onLoggedIn(context);
      }
      else {
        token = null;
        email = null;
        onLoggedOut(context);
      }
    });

    authenticator.signInSilently();
  }

  Future<void> googleSignOut() async {
    authenticator.signOut();
  }

  String getUsername(){
    return userName ?? "Invitado";
  }

  //Returns a map of the headers needed for authentication, sending and receiving
  //JSON requests and responses.
  Map<String, String> createHeaders(){
    return {
      'Content-type': 'application/json;charset=UTF-8',
      'Accept': 'application/json',
      'Authorization': token ?? ""
    };
  }

  //Sends an HTTPS GET request, returns the response. The response could be json
  //object/s on successful or and json object with key 'message' containing the error
  //string provided by the server, as specified in the protocol.
  //WARNING: This method throws exceptions.
  Future<String> sendGET(String path, {Map<String, dynamic>? queryParameters}) async {
    Uri url = Uri.https(apiUrl, path, queryParameters);

    Map<String, String> headers = createHeaders();

    final response = await http.get(url, headers: headers);
    return response.body;
  }

  //Sends an HTTPS POST request, returns the response. The response could be json
  //object/s on successful or and json object with key 'message' containing the error
  //string provided by the server, as specified in the protocol.
  //WARNING: This method throws exceptions.
  Future<String> sendPOST(String path, String request) async {
    Uri url = Uri.https(apiUrl, path);

    Map<String, String> headers = createHeaders();

    final response = await http.post(url, body: request, headers: headers);
    return response.body;
  }

  //Sends an HTTPS PUT request, returns null on successful or
  //the server response on error.
  //WARNING: This method throws exceptions.
  Future<String?> sendPUT(String path, String data) async {
    Uri url = Uri.https(apiUrl, path);

    Map<String, String> headers = createHeaders();

    final response = await http.put(url, body: data, headers: headers);
    if(response.statusCode == 204) { //On request successfully completed
      return null;
    } else { //On error
      return response.body;
    }
  }

  //Sends an HTTPS DELETE request, returns null on successful or
  //the server response on error.
  //WARNING: This method throws exceptions.
  Future<String?> sendDELETE(String path, String data) async {
    Uri url = Uri.https(apiUrl, path);

    Map<String, String> headers = createHeaders();

    final response = await http.delete(url, body: data, headers: headers);
    if(response.statusCode == 204) { //On request successfully completed
      return null;
    } else { //On error
      return response.body;
    }
  }

  //Performs a Google sign out and a sign in.
  //Returns true on success or false on error.
  //Remember that this class executes the provided callbacks on Google user changed,
  //see setUserChangeListener().
  Future<bool> googleSignIn() async {
    try {
      await authenticator.signOut();
      return await authenticator.signIn() != null;
    }
    catch(e, trace){
      if (kDebugMode) {
        print("Error in Google signIn:\n");
        print(e);
        print(trace);
      }
      return false;
    }
  }

  //Resquest all the 'hogar' for this account.
  //Returns a list of 'hogar' on success or null on error.
  Future<List<Hogar>?> getHogares() async {
    //If there is an authenticated user
    if(token != null){
      String response;

      try {
        response = await sendGET(hogaresUrl);
        try {
          return Hogar.fromJsonList(json.decode(response));
        }
        catch(e){
          try {
            if (kDebugMode) {
              Map<String, dynamic> jsonResponse = json.decode(response);
              String error = jsonResponse['mensaje'] ?? "";
              print("Error: Server send error message for 'hogares' GET:\n");
              print(error);
            }
          }
          catch(e){
            if (kDebugMode) {
              print(
                  "Protocol Error: Server returned an unexpected response for 'hogares' GET:");
              print("Response:\n" + response + '\n');
            }
          }
        }
      }
      catch(e, trace){
        if (kDebugMode) {
          print("I/O Error: Error performing 'hogares' GET to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return null;
  }

  //Sends a new 'hogar' to the server.
  //Returns true on success or false on error.
  Future<bool> sendNewHogar(Hogar hogar) async {
    //If there is an authenticated user
    if(token != null) {
      try {
        String response = await sendPOST(hogaresUrl, json.encode(hogar));
        try {
          //The server sends a 'id' on successful completion, or a 'message' on error
          Map<String, dynamic> jsonResponse = json.decode(response);

          if (jsonResponse.containsKey("id")) {
            return true;
          }
          else if (jsonResponse.containsKey("message")) {
            if (kDebugMode) {
              String error = jsonResponse['mensaje'];
              print("Error: Server send error message for 'hogares' GET:\n");
              print(error);
            }
            return false;
          }
          else {
            throw "";
          }
        }
        catch (e) {
          if (kDebugMode) {
            print(
                "Protocol Error: Server returned an unexpected response for 'hogares' POST:");
            print("Response:\n" + response + '\n');
          }
        }
      }
      catch (e, trace) {
        if (kDebugMode) {
          print("I/O Error: Error performing 'hogares' POST to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return false;
  }

  //Request a token for a new 'dispositivo' to the server.
  //Returns the token on success or null on error.
  Future<String?> sendNewDevice(String nombre, Hogar hogar) async {
    //If there is an authenticated user
    if(token != null) {
      String request = jsonEncode({
        "nombre": nombre,
        "hogar": hogar
      });

      try {
        String response = await sendPOST(dispositivosUrl, request);
        try {
          return json.decode(response)["token"];
        }
        catch (e) {
          try {
            if (kDebugMode) {
              Map<String, dynamic> jsonResponse = json.decode(response);
              String error = jsonResponse['mensaje'] ?? "";
              print(
                  "Error: Server send error message for 'dispositivo' POST:\n");
              print(error);
            }
          }
          catch (e) {
            if (kDebugMode) {
              print(
                  "Protocol Error: Server returned an unexpected response for 'dispositivo' POST:");
              print("Response:\n" + response + '\n');
            }
          }
        }
      }
      catch (e, trace) {
        if (kDebugMode) {
          print(
              "I/O Error: Error performing 'dispositivo' POST to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return null;
  }

  //Sends an HTTP GET request for the provided 'hogar' to the server.
  //Returns a list of 'dispositivos' from the 'hogar' on success or null on error
  Future<List<Dispositivo>?> getDispositivosFromHogar(Hogar hogar) async {
    //If there is an authenticated user
    if(token != null){
      String response;

      try {
        ///hogars/:id
        response = await sendGET(hogaresUrl + '/' + hogar.id.toString());
        try {
          return Dispositivo.fromJsonList(json.decode(response));
        }
        catch(e){
          try {
            if (kDebugMode) {
              Map<String, dynamic> jsonResponse = json.decode(response);
              String error = jsonResponse['mensaje'] ?? "";
              print("Error: Server send error message for 'dispositivos' from 'hogare' GET:\n");
              print(error);
            }
          }
          catch(e){
            if (kDebugMode) {
              print(
                  "Protocol Error: Server returned an unexpected response for 'dispositivos' from 'hogare' GET:");
              print("Response:\n" + response + '\n');
            }
          }
        }
      }
      catch(e, trace){
        if (kDebugMode) {
          print("I/O Error: Error performing 'dispositivos' from 'hogare' GET to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return null;
  }

  //Sends an HTTP PUT request for the provided 'hogar' to the server.
  //Returns true on success or false on error
  Future<bool> updateHogar(Hogar hogar) async {
    //If there is an authenticated user
    if(token != null) {
      try {
        String? response = await sendPUT(
            hogaresUrl + "/" + hogar.id.toString(), json.encode(hogar));
        if (response == null) {
          return true;
        }
        else {
          try {
            //The server sends 'message' on error
            Map<String, dynamic> jsonResponse = json.decode(response);

            if (jsonResponse.containsKey("message")) {
              if (kDebugMode) {
                String error = jsonResponse['mensaje'];
                print("Error: Server send error message for 'hogar' PUT:\n");
                print(error);
              }
              return false;
            }
            else {
              throw "";
            }
          }
          catch (e) {
            if (kDebugMode) {
              print(
                  "Protocol Error: Server returned an unexpected response for 'hogar' PUT:");
              print("Response:\n" + response + '\n');
            }
          }
        }
      }
      catch (e, trace) {
        if (kDebugMode) {
          print("I/O Error: Error performing 'hogar' PUT to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return false;
  }

  //Sends an HTTP DELETE request for the provided 'hogar' to the server.
  //Returns true on success or false on error
  Future<bool> deleteHogar(Hogar hogar) async {
    //If there is an authenticated user
    if(token != null){
      try {
        String? response = await sendDELETE(
            hogaresUrl + "/" + hogar.id.toString(), json.encode(hogar));
        if (response == null) {
          return true;
        }
        else {
          try {
            //The server sends 'message' on error
            Map<String, dynamic> jsonResponse = json.decode(response);

            if (jsonResponse.containsKey("message")) {
              if (kDebugMode) {
                String error = jsonResponse['mensaje'];
                print("Error: Server send error message for 'hogar' DELETE:\n");
                print(error);
              }
              return false;
            }
            else {
              throw "";
            }
          }
          catch (e) {
            if (kDebugMode) {
              print(
                  "Protocol Error: Server returned an unexpected response for 'hogar' DELETE:");
              print("Response:\n" + response + '\n');
            }
          }
        }
      }
      catch (e, trace) {
        if (kDebugMode) {
          print("I/O Error: Error performing 'hogar' DELETE to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return false;
  }

  //Sends an HTTP GET request for the provided 'dispositivo' to the server.
  //Returns the list of 'medida' from the 'dispositivo' on success or null on error
  Future<List<Medida>?> getMedidas(Dispositivo dispositivo, DateTime startDate, DateTime endDate) async {
    //If there is an authenticated user
    if(token != null) {
      Map<String, dynamic> queryParameters = {
        "orderBy": "fecha",
        "minDate": startDate.toIso8601String(),
        "maxDate": endDate.toIso8601String(),
      };
      //If there is an authenticated user
      if (token != null) {
        String response;

        try {
          ///dispositivos/:id/medidas
          response = await sendGET(
              dispositivosUrl + '/' + dispositivo.id.toString() + "/medidas/",
              queryParameters: queryParameters
          );
          try {
            return Medida.fromJsonList(json.decode(response));
          }
          catch (e) {
            try {
              if (kDebugMode) {
                Map<String, dynamic> jsonResponse = json.decode(response);
                String error = jsonResponse['mensaje'] ?? "";
                print(
                    "Error: Server send error message for 'medidas' from 'dispositivos' GET:\n");
                print(error);
              }
            }
            catch (e) {
              if (kDebugMode) {
                print(
                    "Protocol Error: Server returned an unexpected response for 'medidas' from 'dispositivos' GET:");
                print("Response:\n" + response + '\n');
              }
            }
          }
        }
        catch (e, trace) {
          if (kDebugMode) {
            print(
                "I/O Error: Error performing 'medidas' from 'dispositivos' GET to the server:\n");
            print(e);
            print(trace.toString());
          }
        }
      }
    }
    return null;
  }

  //Sends an HTTP GET request for the provided 'dispositivo' to the server.
  //Returns the last 'medida' from the 'dispositivo' on success or null on error
  Future<Medida?> getLastMedida(Dispositivo dispositivo) async {
    //If there is an authenticated user
    if(token != null) {
      Map<String, dynamic> queryParameters = {
        "orderBy": "-fecha",
        "limit": 1,
        "offset": 0,
      };
      //If there is an authenticated user
      if (token != null) {
        String response;

        try {
          ///dispositivos/:id/medidas
          response = await sendGET(
              dispositivosUrl + '/' + dispositivo.id.toString() + "/medidas/",
              queryParameters: queryParameters
          );
          try {
            List<Medida> medidas = Medida.fromJsonList(json.decode(response));
            if(medidas.isNotEmpty){
              return medidas.first;
            }
            else{
              return null;
            }
          }
          catch (e) {
            try {
              if (kDebugMode) {
                Map<String, dynamic> jsonResponse = json.decode(response);
                String error = jsonResponse['mensaje'] ?? "";
                print(
                    "Error: Server send error message for last 'medida' from 'dispositivos' GET:\n");
                print(error);
              }
            }
            catch (e) {
              if (kDebugMode) {
                print(
                    "Protocol Error: Server returned an unexpected response for last 'medida' from 'dispositivos' GET:");
                print("Response:\n" + response + '\n');
              }
            }
          }
        }
        catch (e, trace) {
          if (kDebugMode) {
            print(
                "I/O Error: Error performing last 'medida' from 'dispositivos' GET to the server:\n");
            print(e);
            print(trace.toString());
          }
        }
      }
    }
    return null;
  }

  //Sends an HTTP GET request for the provided 'dispositivo' to the server.
  //Returns the 'dispositivo' with statistics from the 'dispositivo' on success or null on error
  Future<Dispositivo?> getDispositivoFromID(Dispositivo dispositivo) async {
    //If there is an authenticated user
    if(token != null){
      String response;

      try {
        ///dispositivos/:id
        response = await sendGET(
            dispositivosUrl + '/' + dispositivo.id.toString()
        );
        try {
          return Dispositivo.fromJson(json.decode(response));
        }
        catch(e){
          try {
            if (kDebugMode) {
              Map<String, dynamic> jsonResponse = json.decode(response);
              String error = jsonResponse['mensaje'] ?? "";
              print("Error: Server send error message for 'dispositivo' with statistics from the 'dispositivo' GET:\n");
              print(error);
            }
          }
          catch(e){
            if (kDebugMode) {
              print(
                  "Protocol Error: Server returned an unexpected response for 'dispositivo' with statistics from the 'dispositivo' GET:");
              print("Response:\n" + response + '\n');
            }
          }
        }
      }
      catch(e, trace){
        if (kDebugMode) {
          print("I/O Error: Error performing 'dispositivo' with statistics from the 'dispositivo' GET to the server:\n");
          print(e);
          print(trace.toString());
        }
      }
    }
    return null;
  }
}
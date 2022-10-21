//This document implements all the JSON objects used to communicate with backend
import 'package:intl/intl.dart';

class Hogar{
  int id;
  String nombre;
  int potencia_contratada;
  List<Dispositivo>? dispositivos;

  Hogar({required this.id, required this.nombre, required this.potencia_contratada,
      this.dispositivos});

  factory Hogar.fromJson(Map<String, dynamic> json){
    return Hogar(
      id: json["id"],
      nombre: json["nombre"],
      potencia_contratada: json["potencia_contratada"],
      dispositivos: json.containsKey("dispositivos") ? Dispositivo.fromJsonList(json["dispositivos"]) : null
    );
  }

  Map toJson() => {
    "id": id,
    "nombre": nombre,
  };

  static List<Hogar> fromJsonList(dynamic json){
    List list = json as List;
    return list.map((tagJson) => Hogar.fromJson(tagJson)).toList();
  }
}

class Usuario{
  int id;
  String nombre;
  String apellidos;
  String email;
  bool notificacion_invitados;

  Usuario({required this.id, required this.nombre, required this.apellidos,
    required this.email, required this.notificacion_invitados});

  factory Usuario.fromJson(Map<String, dynamic> json){
    return Usuario(
        id: json["id"],
        nombre: json["nombre"],
        apellidos: json["apellidos"],
        email: json["email"],
        notificacion_invitados: json["notificacion_invitados"]
    );
  }

  Map toJson() => {
    id: id,
    nombre: nombre,
    apellidos: apellidos,
    email: email,
    notificacion_invitados: notificacion_invitados
  };

  static List<Usuario> fromJsonList(dynamic json){
    List list = json as List;
    return list.map((tagJson) => Usuario.fromJson(tagJson)).toList();
  }
}

class Dispositivo{
  int id;
  String nombre;
  Hogar? hogar;
  Estadistica? estadistica;
  bool? general;
  bool? notificacion;
  int? limite_minimo;
  int? limite_maximo;
  int? tiempo_medida;
  int? tiempo_refrescado;


  Dispositivo({required this.id,required this.nombre, this.hogar, this.estadistica,
      this.general, this.notificacion,this.limite_minimo, this.limite_maximo, this.tiempo_medida,
      this.tiempo_refrescado});

  factory Dispositivo.fromJson(Map<String, dynamic> json){
    return Dispositivo(
      id: json["id"],
      nombre: json["nombre"],
      hogar: json.containsKey("hogar") ? Hogar.fromJson(json["hogar"]) : null,
      estadistica: json.containsKey("estadistica") ? Estadistica.fromJson(json["estadistica"]) : null,
      general: json.containsKey("general") ? json["general"] : null,
      notificacion: json.containsKey("notificacion") ? json["notificacion"] : null,
      limite_minimo: json.containsKey("limite_minimo") ? json["limite_minimo"] : null,
      limite_maximo: json.containsKey("limite_maximo") ? json["limite_maximo"] : null,
      tiempo_medida: json.containsKey("tiempo_medida") ? json["tiempo_medida"] : null,
      tiempo_refrescado: json.containsKey("tiempo_refrescado") ? json["tiempo_refrescado"] : null,
    );
  }

  Map toJson() {
    if(general != null && notificacion != null && limite_minimo != null && limite_maximo != null &&
        tiempo_medida != null && tiempo_refrescado != null){
      return {
        "id": id,
        "nombre": nombre,
        "general": general,
        "notificacion" : notificacion,
        "limite_minimo": limite_minimo,
        "limite_maximo": limite_maximo,
        "tiempo_medida": tiempo_medida,
        "tiempo_refrescado": tiempo_refrescado
      };
    }
    else{
      return {
        "id": id,
        "nombre": nombre
      };
    }
  }

  static List<Dispositivo> fromJsonList(dynamic json){
    List list = json as List;
    return list.map((tagJson) => Dispositivo.fromJson(tagJson)).toList();
  }
}

class Medida{
  int id;
  DateTime fecha;
  double kw;

  Medida({required this.id, required this.fecha, required this.kw});

  factory Medida.fromJson(Map<String, dynamic> json){
    return Medida(
      id: json["intersidad"],
      fecha: DateTime.parse(json["fecha"]),
      kw: json["kw"]
    );
  }

  Map toJson() => {
    "id": id,
    "fecha": fecha.toIso8601String(),
    "kw": kw
  };

  static List<Medida> fromJsonList(dynamic json){
    List list = json as List;
    return list.map((tagJson) => Medida.fromJson(tagJson)).toList();
  }
}

//This class is not defined "as this" in the API, it is more usable in this way
class Historico{
  DateTime date;
  double energia_consumida;
  double precio_estimado;

  Historico({
    required this.date,
    required this.energia_consumida,
    required this.precio_estimado
  });

  factory Historico.fromJson(Map<String, dynamic> json){
    return Historico(
      //Defaults hour, day and month are in the middle of their respective day, month and year
      date: DateTime(json["year"], json["mes"] ?? 6, json["dia"] ?? 15, json["hora"] ?? 12),
      energia_consumida: json["energia_consumida"],
      precio_estimado: json["precio_estimado"]
    );
  }

  Map toJson() => {
    "dia": date.day,
    "mes": date.month,
    "year": date.year,
    "energia_consumida": energia_consumida,
    "precio_estimado": precio_estimado
  };

  static List<Historico> fromJsonList(dynamic json){
    List list = json as List;
    return list.map((tagJson) => Historico.fromJson(tagJson)).toList();
  }
}

class TramosHoras{
  List<DateTime> horas;
  List<double> kw;

  TramosHoras({required this.horas, required this.kw});

  factory TramosHoras.fromJson(Map<String, dynamic> json){
    return TramosHoras(
        horas: getTodayHours(),
        kw: getTodayMeasures(json, getTodayHours())
    );
  }

  static List<DateTime> getTodayHours(){
    return List.generate(24, (index){
      return DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().hour,
      );
    });
  }

  static List<double> getTodayMeasures(Map<String, dynamic> json, List<DateTime> horas){
    return List.generate(horas.length, (index){
      return json[DateFormat("kk:mm").format(horas.elementAt(index))];
    });
  }
}

class TramosSemanal{
  List<int> dias;
  List<double> kw;

  TramosSemanal({required this.dias, required this.kw});

  factory TramosSemanal.fromJson(Map<String, dynamic> json){
    return TramosSemanal(
        dias: getThisWeekDays(),
        kw: getTodayMeasures(json, getThisWeekDays())
    );
  }

  static List<int> getThisWeekDays(){
    return List.generate(7, (index){
      return index;
    });
  }

  static List<double> getTodayMeasures(Map<String, dynamic> json, List<int> dias){
    return List.generate(dias.length, (index){
      return json[index.toString()];
    });
  }
}

class TramosMensual{
  List<int> dias;
  List<double> kw;

  TramosMensual({required this.dias, required this.kw});

  factory TramosMensual.fromJson(Map<String, dynamic> json){
    return TramosMensual(
        dias: getThisYearMoths(),
        kw: getTodayMeasures(json, getThisYearMoths())
    );
  }

  static List<int> getThisYearMoths(){
    return List.generate(12, (index){
      return index;
    });
  }

  static List<double> getTodayMeasures(Map<String, dynamic> json, List<int> dias){
    return List.generate(dias.length, (index){
      return json[index.toString()];
    });
  }
}

class Estadistica{
  DateTime fechaHoy;

  double consumidoHoy;
  double consumidoMes;

  double sumaDiaDinero;
  double sumaMesDinero;

  double mediaKWHDiaria;
  double mediaKWHMensual;

  List<DateTime> tramosHoras;
  List<DateTime> tramoSemanal;
  List<DateTime> tramosMensual;

  TramosHoras tramosHorasMedia;
  TramosSemanal tramosSemanalMedia;
  TramosMensual tramosMensualMedia;

  List<Historico> historicoDiario;
  List<Historico> historicoMensual;

  Estadistica({
    required this.fechaHoy,
    required this.consumidoHoy,
    required this.consumidoMes,
    required this.sumaDiaDinero,
    required this.sumaMesDinero,
    required this.mediaKWHDiaria,
    required this.mediaKWHMensual,
    required this.tramosHoras,
    required this.tramoSemanal,
    required this.tramosMensual,
    required this.tramosHorasMedia,
    required this.tramosSemanalMedia,
    required this.tramosMensualMedia,
    required this.historicoDiario,
    required this.historicoMensual
  });

  factory Estadistica.fromJson(Map<String, dynamic> json){
    return Estadistica(
      fechaHoy: DateTime.parse(json["fechaHoy"]),
      consumidoHoy: json["consumidoHoy"],
      consumidoMes: json["consumidoMes"],
      sumaDiaDinero: json["consumidoMes"],
      sumaMesDinero: json["consumidoMes"],
      mediaKWHDiaria: json["mediaKWHDiaria"],
      mediaKWHMensual: json["mediaKWHMensual"],
      tramosHoras: json["tramosHoras"],
      tramoSemanal: json["tramoSemanal"],
      tramosMensual: json["tramosMensual"],
      tramosHorasMedia: TramosHoras.fromJson(json["tramosHorasMedia"]),
      tramosMensualMedia: TramosMensual.fromJson(json["tramosMensualMedia"]),
      tramosSemanalMedia: TramosSemanal.fromJson(json["tramosSemanalMedia"]),
      historicoDiario: Historico.fromJsonList(json["historicoDiario"]),
      historicoMensual: Historico.fromJsonList(json["historicoMensual"]),
    );
  }
}
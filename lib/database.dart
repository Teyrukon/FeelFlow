import 'dart:async';
import 'dart:convert';

import 'package:feelflow/RemoteDatabase.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FFDatabase {
  final String name;
  late DateTime? date;
  late String? feeling;
  late Map<String, bool>? clothes;
  late double? temperature;
  late double? humidity;
  late double? windSpeed;
  late String? windDirection;
  late Map<String, double>? location;
  late Database database;
  bool isInit = false;
  bool running = false;

  FFDatabase({
    required this.name,
});

  static final Finalizer<Database> _finalizer = Finalizer((connection) => connection.close());

  Future<String> init() async {
    if(isInit){
      return database.path;
    }
    database = await openDatabase(
      join(await getDatabasesPath(), '$name.db'),
      onCreate: (db, version){
        return db.execute(
          'CREATE TABLE IF NOT EXISTS FeelFlow(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, feeling TEXT, clothes BLOB, temperature REAL, humidity REAL, windSpeed REAL, windDirection REAL, location BLOB)'
        );
      },
      version: 1
    );
    return database.path;
  }

  Future<void> close() async {
    await database.close();
  }


  Map<String, dynamic> toMap(){
    return {
      'date': "$date",
      'feeling': feeling as String,
      'clothes': jsonEncode(clothes),
      'temperature': temperature as num,
      'humidity': humidity as num,
      'windSpeed': windSpeed as num,
      'windDirection': windDirection as String,
      'location': jsonEncode(location)
    };
  }

  Future<String> submitData() async {
    String success = "Success";
    if(validateBuffer()){
      database.insert(
        name,
        toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      ).onError((error, stackTrace){
        success = "Error submitting data";
        return -1;
      });
    }else{
      success = "Invalid buffer";
    }
    return success;
  }

  void updateBuffer(Map<String, dynamic> data){
    date = data['date'];
    feeling = data['feeling'];
    clothes = data['clothes'];
    temperature = data['temperature'];
    humidity  = data['humidity'];
    windSpeed = data['windSpeed'];
    windDirection = data['windDirection'];
    location = data['location'];
  }

  bool validateBuffer(){
    return date != null ||
    feeling != null ||
    clothes != null ||
    temperature != null ||
    humidity != null ||
    windSpeed != null ||
    windDirection != null ||
    location != null;
  }
  @override
  String toString(){
    return "date: $date, feeling: $feeling, clothes: $clothes, temperature: $temperature, humidity: $humidity, windSpeed: $windSpeed, windDirection: $windDirection, location: $location";
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    if(!isInit){
      init();
    }
    final List<Map<String, dynamic>> maps = await database.query(name);

    return List.generate(maps.length, (index){
      return {
        'id': maps[index]['id'] as int,
        'date': DateTime.tryParse(maps[index]['date']),
        'feeling': maps[index]['feeling'] as String,
        'clothes': jsonDecode(maps[index]['clothes']) as Map<String, dynamic>,
        'temperature': maps[index]['temperature'] as double,
        'humidity': maps[index]['humidity'] as double,
        'windSpeed': maps[index]['windSpeed'] as double,
        'windDirection': maps[index]['windDirection'] as String,
        'location': jsonDecode(maps[index]['location']) as Map<String, dynamic>
      };
    });
  }

  Future<void> deleteData([int? id, bool? all]) async {
    if(all == true){
      bool run = true;
      int i = 0;
      while(run){
        try{
          await database.delete(
            name,
            where: 'id = ?',
            whereArgs: [i],
          );
          i++;
        }catch (err){
          if (kDebugMode) {
            print(err);
          }
          run = false;
        }
      }
    }else{
      await database.delete(
        name,
        where: 'id = ?',
        whereArgs: [id!],
      );
    }
  }

  Future<int> flushData() async {
    running = true;
    var result = await database.rawDelete('DELETE FROM $name');
    running = false;

    return result;
  }
  List<String> getHeader(){
    fetchData().then((value){
      return value[0].keys.toList();
    }).onError((error, stackTrace){
      return ["Error"];
    });
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllData() async{
    return await database.query(name);
  }
  
  Future<String> sync() async {
    running = true;
    RemoteDatabase remote = RemoteDatabase('host', 'user', 'password', 'name');
    await remote.initialize();
    List<Map<String, dynamic>> localData = await getAllData();

    //verschiebe daten auf remote
    for (var dataRecord in localData) {
      try {
        // Modify this based on your data structure
        Map<String, dynamic> remoteData = {
          'date': dataRecord['date'],
          'feeling': dataRecord['feeling'],
          'clothes': dataRecord['clothes'],
          'weather': {
            'temperature': dataRecord['temperature'],
            'humidity': dataRecord['humidity'],
            'windSpeed': dataRecord['windSpeed'],
            'windDirection': dataRecord['windDirection'],
          },
          'location': dataRecord['location'],
        };

        // Call the method to add data to the remote database
        await remote.addData(remoteData);

        // You might want to delete the record from the local database after a successful sync
        // Uncomment the line below if you want to delete the local record after syncing
        await deleteData(dataRecord['id']);
      } catch (e) {
        if (kDebugMode) {
          print('Error syncing record: $e');
        }
        running = false;
        return 'Error syncing record: $e';
        // Handle the error appropriately (e.g., log it, mark the record as not synced, etc.)
      }
    }
    running = false;
    return 'Success';
  }

}
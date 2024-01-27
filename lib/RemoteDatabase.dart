import 'package:flutter/foundation.dart';
import 'package:mysql1/mysql1.dart';

class RemoteDatabase {
  final String host;
  final int port = 3306;
  final String user;
  final String password;
  final String name;
  late ConnectionSettings settings;
  late MySqlConnection conn;

  RemoteDatabase(this.host, this.user, this.password, this.name);

  static final Finalizer<MySqlConnection> _finalizer = Finalizer((connection) => connection.close());

  Future<void> initialize() async {
    settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: name,
    );
    conn = await MySqlConnection.connect(settings);

    await createTable();
  }

  Future<void> createTable() async {
    try {
      await conn.query('''
        CREATE TABLE IF NOT EXISTS $name (
          id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
          date DATETIME,
          feeling VARCHAR(9),
          clothes JSON,
          temperature DECIMAL(5,2),
          humidity DECIMAL(5,2),
          windSpeed DECIMAL(5,2),
          windDirection VARCHAR(3),
          location JSON
        )
      ''');
    } catch (e) {
      if (kDebugMode) {
        print('Error creating table: $e');
      }
      // Handle the error appropriately
    }
  }

  Future<void> addData(Map<String, dynamic> data) async {
    try {
      await conn.query(
        'INSERT INTO $name (date, feeling, clothes, temperature, humidity, windSpeed, windDirection, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          data['date'],
          data['feeling'],
          data['clothes'],
          data['weather']['temperature'],
          data['weather']['humidity'],
          data['weather']['windSpeed'],
          data['weather']['windDirection'],
          data['location'],
        ],
      );
      if (kDebugMode) {
        print('Record successfully inserted.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting record: $e');
      }
      // Handle the error appropriately
    }
  }
}

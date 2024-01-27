import 'dart:convert';

import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';


class WeatherHandler{
  final String key;
  late double lat;
  late double lon;
  late WeatherFactory wf;
  late DateTime lastFetch;
  late Placemark currentPosition;
  late Placemark lastPosition;
  late SharedPreferences storage;

  Map<String, dynamic> lastWeatherData = {};
  bool isInit = false;
  bool running = false;

  WeatherHandler({
    required this.key,
});

  void init() {
    wf = WeatherFactory(
      key,
      language: Language.GERMAN,
    );
    SharedPreferences.getInstance()
    .then((value){
      storage = value;
      loadData();
    });
  }
  
  void storeData(){
    // ToDo: Fix lastPosition  LateInitializationError
    lastPosition.toJson().keys.toList().forEach((key) {
      storage.setString('lastPosition.$key', lastPosition.toJson()[key]);
    });
    storage.setString('lastFetch', lastFetch.toString());
    lastWeatherData.keys.toList().forEach((key) {
      storage.setString('lastWeatherData.$key', lastWeatherData[key].toString());
    });
  }
  
  void loadData(){
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if(!serviceEnabled){
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        return Future.error('Location permissions are denied');
      }
    }

    if(permission == LocationPermission.deniedForever){
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition();

    lat = position.latitude;
    lon = position.longitude;
    getAdress();
  }

  Future<void> getAdress() async {
    await placemarkFromCoordinates(lat, lon)
    .then((List<Placemark> placemarks){
      Placemark place = placemarks[0];
      currentPosition = place;
    });
  }

  String degToCompass(double? deg){
    int index = ((deg! / 22.5) + 0.5).toInt();
    const List<String> directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];

    return directions[(index % 16)];
  }

  Future<Map<String, dynamic>> fetchData() async {
    lastPosition = currentPosition;
    await getAdress();
    if(lastPosition.locality == currentPosition.locality && lastWeatherData.isNotEmpty){
      return lastWeatherData;
    }

    lastFetch = DateTime.now();
    Weather w = await wf.currentWeatherByLocation(lat, lon);
    lastWeatherData = {
      'temperature': w.temperature!.celsius,
      'humidity': w.humidity!,
      'windSpeed': w.windSpeed!,
      'windDirection': degToCompass(w.windDegree),
      'location': {'lat': double.parse(lat.toStringAsFixed(2)), 'lon': double.parse(lon.toStringAsFixed(2))},
      'date': w.date!
    };
    storeData();
    return lastWeatherData;
  }
}
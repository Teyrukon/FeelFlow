import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite_viewer/sqlite_viewer.dart';
import 'database.dart';
import 'weather.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
      theme: ThemeData.dark(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double sliderValue = 0.0;
  List<bool> checkboxValues = List.generate(12, (index) => false);

  FFDatabase ffdb = FFDatabase(name: 'feelflow');
  WeatherHandler wh = WeatherHandler(key: 'API_KEY');

  final List<String> feelingScala = ["Sehr warm", "Warm", "Gut", "Kalt", "Sehr kalt"];
  final List<String> clothes = ["Lange Hose", "Kurze Hose", "T-Shirt", "Langes Hemd", "Hemd", "Kurzes Hemd", "Pullover", "Winterjacke", "Sommerjacke", "Kurze Unterhose", "Lange Unterhose", "Mütze"];
  Map<String, bool> clothesBuffer = {
    "LH": false,
    "KH": false,
    "TS": false,
    "LHe": false,
    "H": false,
    "KHe": false,
    "P": false,
    "WJ": false,
    "SJ": false,
    "KU": false,
    "LU": false,
    "M": false
  };

  Map<String, dynamic> infoText = {
    'time': "",
    'lat': 0,
    'lon': 0,
    'Adress': ""
  };

  int selectedIndex = 0;

  bool submitState = false;
  bool syncState = false;
  bool flushState = false;

  late Timer timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('FeelFlow'),
            const Expanded(child: SizedBox()),
            IconButton(
              onPressed: (){
                wh.storeData();
                SystemNavigator.pop();
              },
              icon: const Icon(Icons.close),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(child: SizedBox()),
                Text(
                  "Körpertemperatur",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20
                  ),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Text(
                  feelingScala[selectedIndex],
                  style: TextStyle(
                      color: [Colors.red, Colors.orange, Colors.green, Colors.lightBlue, Colors.blue][selectedIndex]
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),

            Slider(
              value: selectedIndex.toDouble(),
              onChanged: (double value) {
                setState(() {
                  selectedIndex = value.toInt();
                });
              },
              min: 0,
              max: feelingScala.length - 1,
              divisions: feelingScala.length - 1,
              activeColor: [Colors.red, Colors.orange, Colors.green, Colors.lightBlue, Colors.blue][selectedIndex],
              thumbColor: [Colors.red, Colors.orange, Colors.green, Colors.lightBlue, Colors.blue][selectedIndex].shade900,
            ),
            const SizedBox(height: 10),
            const Text(
                'Kleidung',
                style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20
            ),),
            IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(clothes.length~/2, (index) {
                      try{
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: clothesBuffer[clothesBuffer.keys.toList()[index]],
                              onChanged: (value) {
                                String label = clothesBuffer.keys.toList()[index];
                                bool verifyBuffer(label){
                                  if (label == "LH" && clothesBuffer["KH"] == true){
                                    return false;
                                  }else if (label == "KH" && clothesBuffer["LH"] ==  true){
                                    return false;
                                  }else if (label == "LHe" &&  clothesBuffer["KHe"] == true){
                                    return false;
                                  }else if (label == "KHe" && clothesBuffer["LHe"] == true){
                                    return false;
                                  }else if (label == "H" && clothesBuffer["KHe"] == true){
                                    return false;
                                  }else if (label == "WJ" && clothesBuffer["SJ"] == true){
                                    return false;
                                  }else if (label == "SJ" && clothesBuffer["WJ"] == true){
                                    return false;
                                  }else{
                                    return true;
                                  }
                                }
                                setState(() {
                                  if(verifyBuffer(label)){
                                    clothesBuffer[label] = value!;
                                  }else{
                                    clothesBuffer[label] = !value!;
                                  }
                                });
                              },
                            ),
                            Text(clothes[index]),
                          ],
                        );
                      } catch (e){
                        return const Row();
                      }
                    }),
                  ),
                  const Expanded(child: VerticalDivider()),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(clothes.length~/2, (index) {
                      index += clothes.length~/2;
                      try{
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: clothesBuffer[clothesBuffer.keys.toList()[index]],
                              onChanged: (value) {
                                String label = clothesBuffer.keys.toList()[index];
                                bool verifyBuffer(label){
                                  if (label == "LH" && clothesBuffer["KH"] == true){
                                    return false;
                                  }else if (label == "KH" && clothesBuffer["LH"] ==  true){
                                    return false;
                                  }else if (label == "LHe" &&  clothesBuffer["KHe"] == true){
                                    return false;
                                  }else if (label == "KHe" && clothesBuffer["LHe"] == true){
                                    return false;
                                  }else if (label == "H" && clothesBuffer["KHe"] == true){
                                    return false;
                                  }else if (label == "WJ" && clothesBuffer["SJ"] == true){
                                    return false;
                                  }else if (label == "SJ" && clothesBuffer["WJ"] == true){
                                    return false;
                                  }else{
                                    return true;
                                  }
                                }
                                setState(() {
                                  if(verifyBuffer(label)){
                                    clothesBuffer[label] = value!;
                                  }else{
                                    clothesBuffer[label] = !value!;
                                  }
                                });
                              },
                            ),
                            Text(clothes[index]),
                          ],
                        );
                      } catch (e){
                        return const Row();
                      }
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TIME: ${infoText['time']}"),
                    Text("LAT: ${infoText['lat']}"),
                    Text("LON: ${infoText['lon']}"),
                    Text("Address: ${infoText['address']}")
                  ],
                )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: submitState ? null : () {
                        setState(() {
                          submitState = true;
                        });
                        if(!ffdb.isInit){
                          ffdb.init();
                        }
                        if(!wh.isInit){
                          wh.init();
                        }

                        Map<String, dynamic> data;
                        wh.fetchData().then((value){
                          data = {
                            'date': value['date'],
                            'feeling': feelingScala[selectedIndex],
                            'clothes': clothesBuffer,
                            'temperature': double.parse(value['temperature'].toStringAsFixed(2)),
                            'humidity': value['humidity'],
                            'windSpeed': value['windSpeed'],
                            'windDirection': value['windDirection'],
                            'location': value['location']
                          };
                          ffdb.updateBuffer(data);
                          ffdb.submitData().then((value){
                            setState(() {
                              submitState = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withOpacity(0.75),
                        foregroundColor: Colors.black,
                      ),
                      label: const Text('Submit'),
                      icon: submitState ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent.withOpacity(0.75),
                          strokeWidth: 3,
                        ),
                      ) : const Icon(Icons.check)
                    ),
                    ElevatedButton.icon(
                      onPressed: syncState ? null : (){
                        setState(() {
                          syncState = true;
                        });
                        if(!ffdb.isInit){
                          ffdb.init();
                        }
                        ffdb.sync();
                        setState(() {
                          syncState = false;
                        });
                      },
                      icon: syncState
                          ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.blueAccent,
                          strokeWidth: 3,
                        ),
                      ) : const Icon(Icons.sync),
                      label: const Text("Sync"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.75),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 25,
                ),
                ElevatedButton(
                    onPressed: (){
                      AlertDialog alert = AlertDialog(
                        title: const Text("Warning"),
                        content: const Text("Confirm the deletion of all data."),
                        actions: [
                          ElevatedButton.icon(
                            onPressed: flushState ? null : (){
                              setState(() {
                                flushState = true;
                              });
                              if(!ffdb.isInit){
                                ffdb.init();
                              }
                              ffdb.flushData();
                              setState(() {
                                flushState = false;
                              });
                              Navigator.of(context).pop();
                            }, 
                            icon: flushState
                                ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ) : const Icon(Icons.delete_forever),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.75),
                              foregroundColor: Colors.black,
                            ),
                            label: const Text("Flush"),
                            
                          ),
                          ElevatedButton (
                            onPressed: (){
                              setState(() {
                                flushState = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text("Abort"),
                          )
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          side: const BorderSide(color: Colors.redAccent)
                        ),
                        icon: const Icon(
                            Icons.warning,
                          color: Colors.red,
                        ),
                      );

                      showDialog(
                        context: context,
                        builder: (context){
                          return alert;
                        }
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.75),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Flush"),
                ),
                const SizedBox(
                  width: 25,
                ),
                ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return FutureBuilder<String>(
                            future: ffdb.init(),
                            builder: (context, snapshot){
                              if(snapshot.connectionState == ConnectionState.done){
                                if(snapshot.hasError){
                                  return const DatabaseList(dbPath: "");
                                }
                                return DatabaseList(dbPath: snapshot.data);
                              }else{
                                return const DatabaseList(dbPath: "");
                              }
                            },
                          );
                        }
                      )
                    );
                  }, child: const Text("DB Viewer"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> infoTask() async {
    if(!wh.isInit){
      wh.init();
    }
    await wh.getLocation();
    DateTime today = DateTime.now();
    await wh.getAdress();
    setState(() {
      infoText['time'] = "${today.day}.${today.month}.${today.year} ${today.hour}:${today.minute}";
      infoText['lat'] = wh.lat;
      infoText['lon'] = wh.lon;
      infoText['address'] = "${wh.currentPosition.postalCode} ${wh.currentPosition.locality}, ${wh.currentPosition.country}";
    });
  }

  @override
  void initState(){
    super.initState();

    timer = Timer.periodic(const Duration(minutes: 1), (Timer t) async {
      await infoTask();
    });

    infoTask();
  }
}



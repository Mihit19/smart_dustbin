import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String wasteLevel = "Unknown";
  String gasLevel = "Unknown";
  String wasteStatus = "";

  @override
  void initState() {
    super.initState();

    // Listen to Firebase updates
    _database.child('WasteLevel').onValue.listen((event) {
      setState(() {
        wasteLevel = event.snapshot.value.toString();
      });
    });

    _database.child('GasLevel').onValue.listen((event) {
      setState(() {
        gasLevel = event.snapshot.value.toString();
      });
    });

    _database.child('DustbinStatus').onValue.listen((event) {
      setState(() {
        wasteStatus = (event.snapshot.value as String?) ?? 'Unknown';
      });
    });
  }

  // Manual control methods
  void _triggerCompaction() {
    _database.child('ManualControl').set('Compaction');
  }

  void _openLid() {
    _database.child('ManualControl').set('OpenLid');
  }

  void _closeLid() {
    _database.child('ManualControl').set('CloseLid');
  }

  void _wasteCollected() {
    _database.child('DustbinStatus').set('Waste Collected');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double fontSize = size.width * 0.05; // Font size relative to screen width
    final double buttonHeight = size.height * 0.07; // Button height relative to screen height

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Waste Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GasGraphScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xfffff0f0),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Waste Level: $wasteLevel",
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Gas Level: $gasLevel",
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  wasteStatus,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.02),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _triggerCompaction,
                    child: Text(
                      "Trigger Compaction",
                      style: TextStyle(fontSize: fontSize * 0.6, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                    onPressed: _openLid,
                    child: Text(
                      "Open Lid",
                      style: TextStyle(fontSize: fontSize * 0.6, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                    onPressed: _closeLid,
                    child: Text(
                      "Close Lid",
                      style: TextStyle(fontSize: fontSize * 0.6, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                    onPressed: _wasteCollected,
                    child: Text(
                      "Waste Collected",
                      style: TextStyle(fontSize: fontSize * 0.6, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GasGraphScreen extends StatefulWidget {
  const GasGraphScreen({super.key});

  @override
  _GasGraphScreenState createState() => _GasGraphScreenState();
}

class _GasGraphScreenState extends State<GasGraphScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<FlSpot> gasDataPoints = [];

  @override
  void initState() {
    super.initState();
    _listenToGasData();
  }

  // Fetch and process gas sensor data from Firebase
  void _listenToGasData() {
    _database.child('GasLevel').onValue.listen((event) {
      double gasValue = double.parse(event.snapshot.value.toString());
      setState(() {
        // Adding new gas data points for the graph
        gasDataPoints.add(FlSpot(gasDataPoints.length.toDouble(), gasValue));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gas Sensor Graph"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: gasDataPoints.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: gasDataPoints,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: const FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 22),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey),
            ),
            gridData: const FlGridData(show: true),
          ),
        ),
      ),
    );
  }
}

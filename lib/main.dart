import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

void main() {
  runApp(SmartGlucoOxyApp());
}

class SmartGlucoOxyApp extends StatefulWidget {
  @override
  _SmartGlucoOxyAppState createState() => _SmartGlucoOxyAppState();
}

class _SmartGlucoOxyAppState extends State<SmartGlucoOxyApp> {
  BluetoothConnection? connection;
  String glucose = "—";
  String oxygen = "—";
  bool isConnecting = false;

  Future<void> connectToBluetooth() async {
    setState(() => isConnecting = true);
    try {
      var bondedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      var hc05 = bondedDevices.firstWhere(
          (device) => device.name == "HC-05",
          orElse: () => throw Exception("لم يتم العثور على HC-05"));

      connection = await BluetoothConnection.toAddress(hc05.address);
      connection!.input!.listen((data) {
        String received = String.fromCharCodes(data).trim();
        List<String> values = received.split(",");
        if (values.length == 2) {
          setState(() {
            glucose = values[0];
            oxygen = values[1];
          });
          sendToTelegram(glucose, oxygen);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ في الاتصال: $e")));
    } finally {
      setState(() => isConnecting = false);
    }
  }

  Future<void> sendToTelegram(String glucose, String oxygen) async {
    String message =
        "📊 القراءات الجديدة:\n\n🩸 نسبة السكر: $glucose mg/dL\n🌬 نسبة الأوكسجين: $oxygen %";
    var url =
        "https://api.telegram.org/bot$BOT_TOKEN/sendMessage?chat_id=$CHAT_ID&text=$message";
    await http.get(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Smart Gluco-Oxy"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🩸 نسبة السكر في الدم", style: TextStyle(fontSize: 22)),
              Text("$glucose mg/dL",
                  style: TextStyle(fontSize: 40, color: Colors.red)),
              SizedBox(height: 30),
              Text("🌬 نسبة الأوكسجين في الدم", style: TextStyle(fontSize: 22)),
              Text("$oxygen %",
                  style: TextStyle(fontSize: 40, color: Colors.green)),
              SizedBox(height: 50),
              ElevatedButton.icon(
                icon: Icon(Icons.bluetooth),
                label: Text(isConnecting ? "جاري الاتصال..." : "اتصال بالبلوتوث"),
                onPressed: isConnecting ? null : connectToBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


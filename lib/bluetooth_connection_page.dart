// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
//
// class BluetoothConnectionPage extends StatefulWidget {
//   @override
//   _BluetoothConnectionPageState createState() => _BluetoothConnectionPageState();
// }
//
// class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
//   List<BluetoothDiscoveryResult> devices = [];
//   bool isScanning = false;
//   List<BluetoothDevice> pairedDevices = [];
//
//   @override
//   void initState() {
//     super.initState();
//     getPairedDevices();
//   }
//
//   void getPairedDevices() async {
//     List<BluetoothDevice> devices = [];
//     try {
//       devices = await FlutterBluetoothSerial.instance.getBondedDevices();
//     } catch (e) {
//       print('Failed to get bonded devices: $e');
//     }
//     setState(() {
//       pairedDevices = devices;
//       isScanning = false;
//     });
//   }
//
//   void startDiscovery() async {
//     setState(() {
//       isScanning = true;
//     });
//
//     FlutterBluetoothSerial.instance
//         .startDiscovery()
//         .listen((r) {
//           if (!pairedDevices.any((device) => device.address == r.device.address)) {
//             setState(() {
//               devices.add(r);
//             });
//           }
//         })
//         .onDone(() {
//           setState(() {
//             isScanning = false;
//           });
//         });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Select Bluetooth Device')),
//       body: Column(
//         children: [
//           if (isScanning) LinearProgressIndicator(),
//           Expanded(
//             child: ListView(
//               children: [
//                 ...pairedDevices.map((device) {
//                   return ListTile(
//                     leading: Icon(Icons.bluetooth_connected),
//                     title: Text(device.name ?? 'Unknown Paired Device'),
//                     subtitle: Text(device.address),
//                     onTap: () {
//                       Navigator.of(context).pop(device.address);
//                     },
//                   );
//                 }).toList(),
//                 if (devices.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                     child: Text('Other Devices', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ),
//                 ...devices.map((r) {
//                   return ListTile(
//                     leading: Icon(Icons.bluetooth),
//                     title: Text(r.device.name ?? 'Unknown Device'),
//                     subtitle: Text(r.device.address),
//                     onTap: () {
//                       Navigator.of(context).pop(r.device.address);
//                     },
//                   );
//                 }).toList(),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: isScanning ? null : startDiscovery,
//               child: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class BluetoothConnectionPage extends StatefulWidget {
  final String? connectedAddress; // <-- add this to know which device is connected
  const BluetoothConnectionPage({super.key, this.connectedAddress});

  @override
  _BluetoothConnectionPageState createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  List<BluetoothDiscoveryResult> discoveredDevices = [];
  List<BluetoothDevice> pairedDevices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    getPairedDevices();
  }

  void getPairedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() => pairedDevices = devices);
    } catch (e) {
      print("Error getting paired devices: $e");
    }
  }

  void startDiscovery() async {
    setState(() {
      discoveredDevices.clear();
      isScanning = true;
    });

    FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((result) {
          if (!discoveredDevices.any((d) => d.device.address == result.device.address)) {
            setState(() => discoveredDevices.add(result));
          }
        })
        .onDone(() {
          setState(() => isScanning = false);
        });
  }

  Widget _buildDeviceTile({required BluetoothDevice device, required bool paired}) {
    bool isConnected = (device.address == widget.connectedAddress);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(
          paired ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isConnected ? Colors.green : (paired ? Colors.blue : Colors.grey),
          size: 32,
        ),
        title: Text(device.name ?? "Unknown Device", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isConnected ? "${device.address}  • Connected" : device.address,
          style: TextStyle(color: isConnected ? Colors.green : Colors.grey[600]),
        ),
        trailing:
            isConnected
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () => Navigator.pop(context, device.address),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Bluetooth Device"),
        actions: [
          if (isScanning)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          if (pairedDevices.isNotEmpty) ...[
            Text("Paired Devices", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...pairedDevices.map((d) => _buildDeviceTile(device: d, paired: true)),
            SizedBox(height: 16),
          ],
          if (discoveredDevices.isNotEmpty) ...[
            Text("Discovered Devices", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...discoveredDevices.map((r) => _buildDeviceTile(device: r.device, paired: false)),
          ],
          if (pairedDevices.isEmpty && discoveredDevices.isEmpty && !isScanning)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  "No devices found.\nTap the scan button to search.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? null : startDiscovery,
        label: Text(isScanning ? "Scanning..." : "Scan"),
        icon: Icon(isScanning ? Icons.search_off : Icons.search),
        backgroundColor: isScanning ? Colors.grey : Colors.blue,
      ),
    );
  }
}

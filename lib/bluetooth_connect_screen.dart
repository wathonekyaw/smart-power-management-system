// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
//
// class BluetoothConnectScreen extends StatefulWidget {
//   const BluetoothConnectScreen({super.key});
//
//   @override
//   State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
// }
//
// class _BluetoothConnectScreenState extends State<BluetoothConnectScreen> {
//   BluetoothDevice? selectedDevice;
//   bool _connecting = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Bluetooth Pairing"), backgroundColor: Colors.blue.shade700),
//       body: Column(
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               'Select a device to connect',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: FutureBuilder<List<BluetoothDevice>>(
//               future: FlutterBluetoothSerial.instance.getBondedDevices(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 final devices = snapshot.data!;
//                 if (devices.isEmpty) {
//                   return const Center(child: Text("No paired devices found"));
//                 }
//
//                 return ListView.builder(
//                   itemCount: devices.length,
//                   itemBuilder: (context, index) {
//                     final device = devices[index];
//                     return ListTile(
//                       leading: const Icon(Icons.bluetooth, color: Colors.blue),
//                       title: Text(device.name ?? "Unknown Device"),
//                       subtitle: Text(device.address),
//                       trailing: ElevatedButton(
//                         child:
//                             _connecting && selectedDevice == device
//                                 ? const SizedBox(
//                                   height: 16,
//                                   width: 16,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                                 : const Text("Connect"),
//                         onPressed:
//                             _connecting
//                                 ? null
//                                 : () async {
//                                   setState(() {
//                                     _connecting = true;
//                                     selectedDevice = device;
//                                   });
//                                   try {
//                                     BluetoothConnection connection =
//                                         await BluetoothConnection.toAddress(device.address);
//
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text("Connected to ${device.name}")),
//                                     );
//
//                                     Navigator.pop(context, connection);
//                                   } catch (e) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text("Failed to connect: $e")),
//                                     );
//                                   } finally {
//                                     setState(() => _connecting = false);
//                                   }
//                                 },
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

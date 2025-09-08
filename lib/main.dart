import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

import 'bluetooth_connection_page.dart';

void main() {
  runApp(const PowerManagementApp());
}

class PowerManagementApp extends StatelessWidget {
  const PowerManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Power Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        fontFamily: 'Roboto',
      ),
      home: const PowerManagementHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PowerManagementHomePage extends StatefulWidget {
  const PowerManagementHomePage({super.key});

  @override
  _PowerManagementHomePageState createState() => _PowerManagementHomePageState();
}

class _PowerManagementHomePageState extends State<PowerManagementHomePage> {
  // Bluetooth
  BluetoothConnection? connection;
  bool isConnecting = false;
  bool isConnected = false;
  String? connectedAddress;
  Timer? reconnectTimer;

  // Power info
  String _currentPowerSource = 'None';
  String _currentSourceStatus = 'No Power Source';
  double _batteryLevel = 0;
  bool _solarAvailable = false;
  bool _gridAvailable = false;

  // Lamp states
  bool _lampHighOn = false;
  bool _lampNormalOn = false;
  bool _lampLowOn = false;

  // Manual overrides
  bool _manualOverrideHigh = false;
  bool _manualOverrideNormal = false;
  bool _manualOverrideLow = false;

  // Debug logs
  List<String> _debugLogs = [];
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _addLog('App initialized');
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      _debugLogs.add('[$timestamp] $message');
      if (_debugLogs.length > 100) _debugLogs.removeAt(0); // Limit to 100 logs
    });
  }

  void connectToBluetooth(String address) async {
    try {
      _addLog('Connecting to $address');
      setState(() => isConnecting = true);
      BluetoothConnection connectionResult = await BluetoothConnection.toAddress(address);
      connection = connectionResult;
      connectedAddress = address;
      setState(() {
        isConnecting = false;
        isConnected = true;
      });
      _addLog('Connected to $address');

      connection!.input!.listen((data) {
        String received = utf8.decode(data).trim();
        _addLog('Received: $received');
        parseBluetoothData(received);
      }).onDone(() {
        _addLog('Bluetooth connection closed');
        setState(() => isConnected = false);
        attemptReconnect();
      });
    } catch (e) {
      _addLog('Cannot connect: $e');
      setState(() {
        isConnecting = false;
        isConnected = false;
      });
      attemptReconnect();
    }
  }

  void attemptReconnect() {
    if (connectedAddress == null) return;
    if (reconnectTimer != null && reconnectTimer!.isActive) return;

    reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isConnected) {
        _addLog('Attempting to reconnect to $connectedAddress');
        connectToBluetooth(connectedAddress!);
      } else {
        timer.cancel();
      }
    });
  }

  void parseBluetoothData(String data) {
    try {
      final parts = data.split(',');
      _addLog('Parsed parts: ${parts.length} parts');
      if (parts.length >= 8) {
        setState(() {
          _currentPowerSource = parts[0];
          _currentSourceStatus = parts[1];
          _batteryLevel = double.tryParse(parts[2]) ?? 0;
          _lampHighOn = parts[3] == '1';
          _lampNormalOn = parts[4] == '1';
          _lampLowOn = parts[5] == '1';
          _solarAvailable = parts[6] == '1';
          _gridAvailable = parts[7] == '1';
        });
      } else {
        _addLog('Invalid Bluetooth data: too few parts ($data)');
      }
    } catch (e) {
      _addLog('Parse error: $e');
    }
  }

  void sendLampCommand(String lamp, bool value) {
    if (connection != null && connection!.isConnected) {
      String commandString = '$lamp:${value ? 1 : 0}\n';
      _addLog('Sending: $commandString');
      connection!.output.add(utf8.encode(commandString));
    } else {
      _addLog('Cannot send command: not connected');
    }
  }

  Widget _buildPowerSourceCard(String label, IconData icon, bool isAvailable, bool isActive) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        color: isActive ? const Color(0xFF2196F3) : (isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive || isAvailable ? Colors.white : Colors.grey[700], size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive || isAvailable ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Battery Level',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _batteryLevel > 20 ? Icons.battery_charging_full : Icons.battery_alert,
                  color: _batteryLevel > 20 ? Colors.green : Colors.red,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _batteryLevel / 100,
                    backgroundColor: Colors.grey[300],
                    color: _batteryLevel > 40 ? Colors.green : Colors.red,
                    minHeight: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _currentPowerSource == 'Battery' ? _currentSourceStatus : '${_batteryLevel.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Power Source', _currentPowerSource, Icons.power),
            _buildStatusRow('Source Status', _currentSourceStatus, Icons.info_outline),
            _buildStatusRow(
              'Lamps',
              'High: ${_lampHighOn ? 'ON' : 'OFF'}, Normal: ${_lampNormalOn ? 'ON' : 'OFF'}, Low: ${_lampLowOn ? 'ON' : 'OFF'}',
              Icons.lightbulb_outline,
            ),
            _buildStatusRow('Solar Available', _solarAvailable ? 'Yes' : 'No', Icons.wb_sunny),
            _buildStatusRow('Grid Available', _gridAvailable ? 'Yes' : 'No', Icons.electrical_services),
          ],
        ),
      ),
    );
  }

  Widget _buildLampCard(String label, IconData icon, bool isSystemOn, bool manualOverride, Function(bool) setManualOverride) {
    bool isLampOn = manualOverride && isSystemOn;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: isLampOn ? 8 : 5,
      color: isLampOn ? const Color(0xFFFFF9C4) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: isLampOn ? Colors.yellow[700] : Colors.grey, size: 32),
                const SizedBox(width: 16),
                Text(
                  '$label Lamp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLampOn ? Colors.black87 : Colors.grey[700],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Manual Override',
                  style: TextStyle(
                    fontSize: 12,
                    color: manualOverride ? Colors.blue : Colors.grey[600],
                  ),
                ),
                Switch(
                  value: manualOverride,
                  onChanged: (value) {
                    setState(() {
                      setManualOverride(value);
                    });
                    sendLampCommand(label.toLowerCase(), value);
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugLogCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: ExpansionTile(
        title: const Text(
          'Debug Logs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              reverse: true, // Show newest logs at the top
              itemCount: _debugLogs.length,
              itemBuilder: (context, index) {
                return Text(
                  _debugLogs[_debugLogs.length - 1 - index], // Reverse order
                  style: const TextStyle(fontSize: 12, fontFamily: 'Courier'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildStatusRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(child: Text('$title: $value', style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildConnectionBar() {
    Color color = isConnected ? Colors.green[400]! : (isConnecting ? Colors.orange[400]! : Colors.red[400]!);
    String statusText = isConnected ? 'Connected' : (isConnecting ? 'Connecting...' : 'Disconnected');
    IconData icon = isConnected ? Icons.bluetooth_connected : (isConnecting ? Icons.bluetooth : Icons.bluetooth_disabled);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
            onPressed: () async {
              final address = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BluetoothConnectionPage(connectedAddress: connectedAddress),
                ),
              );
              if (address != null) {
                connectToBluetooth(address);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    reconnectTimer?.cancel();
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Smart Power Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF0F2F5),
      ),
      body: Column(
        children: [
          _buildConnectionBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  _buildSectionHeader('Power Status'),
                  Row(
                    children: [
                      _buildPowerSourceCard('Solar', Icons.wb_sunny, _solarAvailable, _currentPowerSource == 'Solar'),
                      const SizedBox(width: 12),
                      _buildPowerSourceCard('Grid', Icons.electrical_services, _gridAvailable, _currentPowerSource == 'Grid'),
                      const SizedBox(width: 12),
                      _buildPowerSourceCard('Battery', Icons.battery_full, _currentPowerSource == 'Battery', _currentPowerSource == 'Battery'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBatteryCard(),
                  _buildSectionHeader('Lamp Controls'),
                  _buildLampCard(
                    'High',
                    Icons.lightbulb,
                    _lampHighOn,
                    _manualOverrideHigh,
                        (v) => _manualOverrideHigh = v,
                  ),
                  const SizedBox(height: 12),
                  _buildLampCard(
                    'Normal',
                    Icons.lightbulb,
                    _lampNormalOn,
                    _manualOverrideNormal,
                        (v) => _manualOverrideNormal = v,
                  ),
                  const SizedBox(height: 12),
                  _buildLampCard(
                    'Low',
                    Icons.lightbulb,
                    _lampLowOn,
                    _manualOverrideLow,
                        (v) => _manualOverrideLow = v,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Debug Logs'),
                  _buildDebugLogCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino Lamp Control Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto', // A common, clean font
      ),
      home: const LampControlScreen(),
    );
  }
}

class LampControlScreen extends StatefulWidget {
  const LampControlScreen({super.key});

  @override
  _LampControlScreenState createState() => _LampControlScreenState();
}

class _LampControlScreenState extends State<LampControlScreen> {
  // --- State Variables ---
  // Power source availability
  bool _isSolarOn = false;
  bool _isGridOn = false;
  bool _isBatteryOn = true; // Battery is generally assumed available if not explicitly off
  double _batteryLevel = 80; // Battery level in percentage (0-100)

  // Current time for grid peak hour logic
  DateTime _currentTime = DateTime.now();
  late Timer _timer;

  // Lamp states (controlled by logic or manual override)
  bool _lampHighOn = false;
  bool _lampNormalOn = false;
  bool _lampLowOn = false;

  // Manual override states for each lamp
  bool _manualOverrideHigh = false;
  bool _manualOverrideNormal = false;
  bool _manualOverrideLow = false;

  // Display information
  String _currentPowerSource = 'None';
  String _currentSourceStatus = 'No Power Source';

  @override
  void initState() {
    super.initState();
    // Initialize time and start timer for updates
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());
    // Initial lamp control logic run
    _controlLamps();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  // --- Time Update Function ---
  void _updateTime() {
    setState(() {
      _currentTime = DateTime.now();
      _controlLamps(); // Recalculate lamp states based on new time
    });
  }

  // --- Core Logic Function ---
  // This function determines the lamp states based on power source priority
  // and updates the display information.
  void _controlLamps() {
    bool newHighOn = false;
    bool newNormalOn = false;
    bool newLowOn = false;
    String source = 'None';
    String status = 'No Power Source Available';

    // --- Power Source Priority Logic ---
    if (_isSolarOn) {
      // Solar is highest priority: All 3 lamps on
      newHighOn = true;
      newNormalOn = true;
      newLowOn = true;
      source = 'Solar';
      status = 'All Lamps On';
    } else if (_isGridOn) {
      // Grid is second priority
      final isPeakHour = _currentTime.hour >= 9 && _currentTime.hour < 10; // 9:00 AM to 9:59 AM
      if (isPeakHour) {
        // Peak Hour: High and Normal lamps on
        newHighOn = true;
        newNormalOn = true;
        newLowOn = false;
        source = 'Grid';
        status = 'Peak Hour (9:00 AM - 10:00 AM)';
      } else {
        // Other times: All 3 lamps on
        newHighOn = true;
        newNormalOn = true;
        newLowOn = true;
        source = 'Grid';
        status = 'No Peak Hour';
      }
    } else if (_isBatteryOn) {
      // Battery is lowest priority (only if Solar and Grid are off)
      if (_batteryLevel > 40) {
        // Battery level > 40%: High and Normal lamps on
        newHighOn = true;
        newNormalOn = true;
        newLowOn = false;
        source = 'Battery';
        status = 'Battery > 40% (${_batteryLevel.toInt()}%)';
      } else {
        // Battery level <= 40%: High lamp on
        newHighOn = true;
        newNormalOn = false;
        newLowOn = false;
        source = 'Battery';
        status = 'Battery < 40% (${_batteryLevel.toInt()}%)';
      }
    } else {
      // No power source available
      newHighOn = false;
      newNormalOn = false;
      newLowOn = false;
      source = 'None';
      status = 'No Power Source Available';
    }

    // Apply manual overrides if they are active (they take precedence)
    setState(() {
      _lampHighOn = _manualOverrideHigh || newHighOn;
      _lampNormalOn = _manualOverrideNormal || newNormalOn;
      _lampLowOn = _manualOverrideLow || newLowOn;

      _currentPowerSource = source;
      _currentSourceStatus = status;
    });
  }

  // --- Helper Widgets ---
  Widget _buildToggleSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            Switch.adaptive(value: value, onChanged: onChanged, activeColor: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLampIndicator(String name, bool isOn) {
    return Column(
      children: [
        Icon(
          isOn ? Icons.lightbulb : Icons.lightbulb_outline,
          color: isOn ? Colors.amber : Colors.grey,
          size: 60,
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isOn ? Colors.amber.shade800 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Power Management Simulator'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Current Status Display ---
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'System Status',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildStatusRow('Current Power Source:', _currentPowerSource),
                    _buildStatusRow('Status Details:', _currentSourceStatus),
                    _buildStatusRow(
                      'Current Time:',
                      '${_currentTime.hour}:${_currentTime.minute.toString().padLeft(2, '0')}',
                    ),
                    _buildStatusRow('Solar On:', _isSolarOn ? 'Yes' : 'No'),
                    _buildStatusRow('Grid On:', _isGridOn ? 'Yes' : 'No'),
                    _buildStatusRow('Battery Available:', _isBatteryOn ? 'Yes' : 'No'),
                    _buildStatusRow('Battery Level:', '${_batteryLevel.toInt()}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Lamp Indicators ---
            const Text(
              'Lamp States',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLampIndicator('High', _lampHighOn),
                _buildLampIndicator('Normal', _lampNormalOn),
                _buildLampIndicator('Low', _lampLowOn),
              ],
            ),
            const SizedBox(height: 20),

            // --- Power Source Controls ---
            const Text(
              'Power Source Controls',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _buildToggleSwitch(
              title: 'Solar Power On',
              value: _isSolarOn,
              onChanged: (value) {
                setState(() {
                  _isSolarOn = value;
                });
                _controlLamps();
              },
            ),
            _buildToggleSwitch(
              title: 'Grid Power On',
              value: _isGridOn,
              onChanged: (value) {
                setState(() {
                  _isGridOn = value;
                });
                _controlLamps();
              },
            ),
            _buildToggleSwitch(
              title: 'Battery Available',
              value: _isBatteryOn,
              onChanged: (value) {
                setState(() {
                  _isBatteryOn = value;
                });
                _controlLamps();
              },
            ),
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Level: ${_batteryLevel.toInt()}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: _batteryLevel,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _batteryLevel.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          _batteryLevel = value;
                        });
                        _controlLamps();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Manual Lamp Overrides ---
            const Text(
              'Manual Lamp Overrides',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _buildToggleSwitch(
              title: 'Manual High Lamp',
              value: _manualOverrideHigh,
              onChanged: (value) {
                setState(() {
                  _manualOverrideHigh = value;
                });
                _controlLamps();
              },
            ),
            _buildToggleSwitch(
              title: 'Manual Normal Lamp',
              value: _manualOverrideNormal,
              onChanged: (value) {
                setState(() {
                  _manualOverrideNormal = value;
                });
                _controlLamps();
              },
            ),
            _buildToggleSwitch(
              title: 'Manual Low Lamp',
              value: _manualOverrideLow,
              onChanged: (value) {
                setState(() {
                  _manualOverrideLow = value;
                });
                _controlLamps();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for status display rows
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RetrievalLocationsScreen extends StatefulWidget {
  const RetrievalLocationsScreen({super.key});

  @override
  State<RetrievalLocationsScreen> createState() =>
      _RetrievalLocationsScreenState();
}

class _RetrievalLocationsScreenState extends State<RetrievalLocationsScreen> {
  bool _isTracking = false;
  double? _lat;
  double? _lng;
  StreamSubscription? _serviceSubscription;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _listenToServiceUpdates();
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (mounted) {
      setState(() {
        _isTracking = isRunning;
      });
    }
  }

  void _listenToServiceUpdates() {
    final service = FlutterBackgroundService();
    _serviceSubscription = service.on('update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _lat = event['lat'] as double?;
          _lng = event['lng'] as double?;
        });
      }
    });
  }

  Future<void> _toggleTracking() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (isRunning) {
      // Stop Tracking
      service.invoke('stopService');
      setState(() {
        _isTracking = false;
        _lat = null;
        _lng = null;
      });
    } else {
      // Start Tracking
      // 1. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
          );
        }
        // Optionally ask user to open location settings:
        // await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permissions are permanently denied, we cannot request permissions.')),
          );
        }
        return;
      }

      // 2. Start Service
      await service.startService();
      setState(() {
        _isTracking = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retrieval Locations'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _isTracking ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isTracking ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTracking ? Icons.gps_fixed : Icons.gps_off,
                      color: _isTracking ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isTracking ? 'Tracking Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isTracking ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Coordinates Display
              if (_isTracking && _lat != null && _lng != null) ...[
                const Text(
                  'Current Location:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lat: ${_lat!.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lng: ${_lng!.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ] else if (_isTracking) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Waiting for GPS signal...'),
              ] else ...[
                const Text(
                  'Press Start to begin sharing your location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],

              const Spacer(),

              // Toggle Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _isTracking ? 'STOP TRACKING' : 'START TRACKING',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

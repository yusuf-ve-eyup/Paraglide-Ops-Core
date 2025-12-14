import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Note: We use the existing LocationService configuration from lib/services/location_service.dart
// effectively by interacting with the singleton FlutterBackgroundService.

class RetrievalLocationsScreen extends StatefulWidget {
  const RetrievalLocationsScreen({super.key});

  @override
  State<RetrievalLocationsScreen> createState() =>
      _RetrievalLocationsScreenState();
}

class _RetrievalLocationsScreenState extends State<RetrievalLocationsScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  
  String? _groupId;
  String? _userId;
  Stream<DatabaseEvent>? _pilotsStream;
  
  final Distance _distanceCalculator = const Distance();

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  Future<void> _initSystem() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _groupId = prefs.getString('groupId');
      _userId = prefs.getString('userId');
    });

    if (_groupId != null) {
      _pilotsStream = FirebaseDatabase.instance
          .ref('groups/$_groupId/pilots')
          .onValue
          .asBroadcastStream();
    }

    if (_groupId != null && _userId != null) {
      _checkPermissionsAndStart();
    }
  }

  Future<void> _checkPermissionsAndStart() async {
    // 1. Check Service Enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnackBar('Lütfen cihazınızın GPS özelliğini açın.');
      return;
    }

    // 2. Check Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnackBar('Konum izni reddedildi.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnackBar('Konum izni kalıcı olarak reddedildi. Ayarlardan açmalısınız.');
      return;
    }

    // 3. Enforce "Always Allow" for Background Service
    if (permission == LocationPermission.whileInUse) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Arka Plan İzni Gerekli'),
            content: const Text(
                'Uygulamanın arka planda konumunuzu paylaşabilmesi için konum iznini "Her zaman izin ver" olarak ayarlamanız gerekmektedir.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        );
      }
      return; // Do not proceed
    }

    // 4. Start Service if Permitted
    if (permission == LocationPermission.always) {
      _startBackgroundService();
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_currentLocation!, 13);
      }
    } catch (e) {
      debugPrint("İlk konum alınamadı: $e");
    }
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    
    // Listen for UI updates from service (sent via 'update' or 'error')
    service.on('update').listen((event) {
      if (event != null && mounted) {
        final lat = event['lat'] as double?;
        final lng = event['lng'] as double?;
        if (lat != null && lng != null) {
          // Update state if significant change or first time
          if (_currentLocation == null || 
              _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, LatLng(lat, lng)) > 5) {
            setState(() {
              _currentLocation = LatLng(lat, lng);
            });
          }
        }
      }
    });

    // We assume the service is already configured in main.dart -> LocationService.initialize()
    // So we just check if running, and start if not.
    if (!await service.isRunning()) {
      service.startService();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Helper: Process Data from Firebase
  List<Map<String, dynamic>> _processPilots(DataSnapshot snapshot) {
    final rawData = snapshot.value;
    if (rawData == null) return [];

    List<Map<String, dynamic>> pilots = [];
    
    // Handle both List and Map structures from Firebase
    if (rawData is Map) {
      rawData.forEach((key, value) {
        if (value is Map) {
          final p = Map<String, dynamic>.from(value);
          p['key'] = key;
          pilots.add(p);
        }
      });
    } else if (rawData is List) {
      for (int i = 0; i < rawData.length; i++) {
        if (rawData[i] != null && rawData[i] is Map) {
          final p = Map<String, dynamic>.from(rawData[i]);
          p['key'] = i.toString();
          pilots.add(p);
        }
      }
    }

    // Filter: Assigned to me AND Status is waiting
    pilots = pilots.where((p) {
      return p['retrieverId'].toString() == _userId && p['status'] == 'waiting';
    }).toList();

    // Sort: Distance Ascending
    if (_currentLocation != null) {
      pilots.sort((a, b) {
        final latA = (a['locationX'] as num?)?.toDouble() ?? 0;
        final lngA = (a['locationY'] as num?)?.toDouble() ?? 0;
        final latB = (b['locationX'] as num?)?.toDouble() ?? 0;
        final lngB = (b['locationY'] as num?)?.toDouble() ?? 0;
        
        final distA = _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, LatLng(latA, lngA));
        final distB = _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, LatLng(latB, lngB));
        
        return distA.compareTo(distB);
      });
    }

    return pilots;
  }
  
  Future<void> _markAsRetrieved(String pilotId, String name) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Onay'),
        content: Text('$name alındı olarak işaretlensin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onayla')),
        ],
      ),
    );

    if (confirm == true && _groupId != null) {
      // Mark as taked
      await FirebaseDatabase.instance.ref('groups/$_groupId/pilots/$pilotId').update({
        'status': 'taked',
        'wtsc': ServerValue.timestamp,
      });
    }
  }

  void _launchMap(double lat, double lng) async {
     final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
     try {
       await launchUrl(uri, mode: LaunchMode.externalApplication);
     } catch(e) {
       debugPrint("Harita hatası: $e");
       if(mounted) _showSnackBar("Harita açılamadı.");
     }
  }

  void _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retrieval Dashboard'),
      ),
      body: _groupId == null || _userId == null 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DatabaseEvent>(
              stream: _pilotsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Veri hatası: ${snapshot.error}'));
                }
                
                List<Map<String, dynamic>> pilots = [];
                if (snapshot.hasData) {
                  pilots = _processPilots(snapshot.data!.snapshot);
                }

                return Column(
                  children: [
                    // MAP SECTION
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation ?? const LatLng(39.93, 32.85),
                          initialZoom: 13,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.retrieve_app',
                          ),
                          // My Location
                          if (_currentLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.navigation, color: Colors.blue, size: 30),
                                ),
                              ],
                            ),
                          // Pilots
                          MarkerLayer(
                            markers: pilots.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final p = entry.value;
                              final lat = (p['locationX'] as num?)?.toDouble() ?? 0;
                              final lng = (p['locationY'] as num?)?.toDouble() ?? 0;
                              
                              return Marker(
                                point: LatLng(lat, lng),
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.red, size: 40),
                                    Positioned(
                                      top: 5,
                                      child: Text(
                                        "$index",
                                        style: const TextStyle(
                                          color: Colors.white, 
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // PILOT LIST
                    Expanded(
                      child: pilots.isEmpty
                          ? const Center(child: Text('Aktif görev bulunamadı.'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: pilots.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = pilots[index];
                                final pilotId = p['key'];
                                final name = p['nameSurname'] ?? 'İsimsiz Pilot';
                                final phone = p['phoneNumber'];
                                final lat = (p['locationX'] as num?)?.toDouble() ?? 0;
                                final lng = (p['locationY'] as num?)?.toDouble() ?? 0;
                                
                                String distText = "";
                                if (_currentLocation != null) {
                                  final dist = _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, LatLng(lat, lng));
                                  distText = dist > 1000 
                                      ? "${(dist/1000).toStringAsFixed(1)} km" 
                                      : "${dist.round()} m";
                                }

                                return Card(
                                  elevation: 2,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      child: Text(
                                        "${index + 1}", 
                                        style: const TextStyle(fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(distText.isNotEmpty ? "Mesafe: $distText" : "Konum bekleniyor..."),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _launchPhone(phone?.toString()),
                                                icon: const Icon(Icons.phone, size: 18),
                                                label: const Text(
                                                  "Ara", 
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  foregroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _launchMap(lat, lng),
                                                icon: const Icon(Icons.map, size: 18),
                                                label: const Text(
                                                  "Harita",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                 style: OutlinedButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  foregroundColor: Colors.blue,
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    trailing: Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: false, // Always false until checked, then it disappears from list
                                        onChanged: (val) {
                                          if (val == true) {
                                            _markAsRetrieved(pilotId, name);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

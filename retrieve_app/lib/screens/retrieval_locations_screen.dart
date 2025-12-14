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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnackBar('Lütfen cihazınızın GPS özelliğini açın.');
      return;
    }

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
      return; 
    }

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
    
    service.on('update').listen((event) {
      if (event != null && mounted) {
        final lat = event['lat'] as double?;
        final lng = event['lng'] as double?;
        if (lat != null && lng != null) {
          if (_currentLocation == null || 
              _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, LatLng(lat, lng)) > 5) {
            setState(() {
              _currentLocation = LatLng(lat, lng);
            });
          }
        }
      }
    });

    if (!await service.isRunning()) {
      service.startService();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Map<String, dynamic>> _processPilots(DataSnapshot snapshot) {
    final rawData = snapshot.value;
    if (rawData == null) return [];

    List<Map<String, dynamic>> pilots = [];
    
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

    pilots = pilots.where((p) {
      return p['retrieverId'].toString() == _userId && p['status'] == 'waiting';
    }).toList();

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
        title: const Text('Confirm Retrieval'),
        content: Text('Mark $name as retrieved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm == true && _groupId != null) {
      await FirebaseDatabase.instance.ref('groups/$_groupId/pilots/$pilotId').update({
        'status': 'taked',
        'wtsc': ServerValue.timestamp,
      });

      final retrieverRef = FirebaseDatabase.instance.ref('groups/$_groupId/retrievers/$_userId');
      await retrieverRef.update({
        'taskCount': ServerValue.increment(-1),
      });
    }
  }

  void _launchMap(double lat, double lng) async {
     final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
     try {
       await launchUrl(uri, mode: LaunchMode.externalApplication);
     } catch(e) {
       debugPrint("Map error: $e");
       if(mounted) _showSnackBar("Could not open map.");
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
                  return Center(child: Text('Data Error: ${snapshot.error}'));
                }
                
                List<Map<String, dynamic>> pilots = [];
                if (snapshot.hasData) {
                  pilots = _processPilots(snapshot.data!.snapshot);
                }

                return Column(
                  children: [
                    // Styled Map Container
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: ClipRect( // Ensures markers don't overflow visibly if clipped
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
                            if (_currentLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentLocation!,
                                    width: 50,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black26, blurRadius: 4),
                                        ]
                                      ),
                                      child: const Icon(Icons.navigation, color: Colors.indigo, size: 30),
                                    ),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: pilots.asMap().entries.map((entry) {
                                final index = entry.key + 1;
                                final p = entry.value;
                                final lat = (p['locationX'] as num?)?.toDouble() ?? 0;
                                final lng = (p['locationY'] as num?)?.toDouble() ?? 0;
                                
                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 45,
                                  height: 45,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.deepOrange, size: 45),
                                      Positioned(
                                        top: 8,
                                        child: Text(
                                          "$index",
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontSize: 14, 
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
                    ),
                    
                    // Task List
                    Expanded(
                      child: pilots.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No active tasks assigned.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder( // Changed to builder for Cards
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: pilots.length,
                              itemBuilder: (context, index) {
                                final p = pilots[index];
                                final pilotId = p['key'];
                                final name = p['nameSurname'] ?? 'Unknown Pilot';
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
                                  elevation: 3,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            // Index Circle
                                            Container(
                                              width: 40,
                                              height: 40,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: Colors.indigo,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                "${index + 1}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Pilot Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.near_me, size: 16, color: Colors.grey[600]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        distText.isNotEmpty ? distText : "Locating...",
                                                        style: TextStyle(color: Colors.grey[700]),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        "• Waiting",
                                                        style: TextStyle(
                                                          color: Colors.green, 
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Checkbox
                                            Transform.scale(
                                              scale: 1.3,
                                              child: Checkbox(
                                                value: false, 
                                                activeColor: Colors.green,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                onChanged: (val) {
                                                  if (val == true) {
                                                    _markAsRetrieved(pilotId, name);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        // Action Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _launchPhone(phone?.toString()),
                                                icon: const Icon(Icons.phone, size: 20),
                                                label: const Text("Call Pilot"),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.green,
                                                  side: const BorderSide(color: Colors.green),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _launchMap(lat, lng),
                                                icon: const Icon(Icons.map, size: 20),
                                                label: const Text("Navigate"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.indigo,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
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

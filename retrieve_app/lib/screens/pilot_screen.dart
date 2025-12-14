import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class PilotScreen extends StatefulWidget {
  const PilotScreen({super.key});

  @override
  State<PilotScreen> createState() => _PilotScreenState();
}

class _PilotScreenState extends State<PilotScreen> {
  String? _groupId;
  String? _userId; // Pilot ID
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _groupId = prefs.getString('groupId');
        _userId = prefs.getString('userId');
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _sendLocation() async {
    if (_groupId == null || _userId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // 2. Get Position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Update Firebase
      final ref = FirebaseDatabase.instance
          .ref('groups/$_groupId/pilots/$_userId');

      await ref.update({
        'status': 'landed',
        'locationX': position.latitude,
        'locationY': position.longitude,
        'wtsc': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sent! Waiting for retriever.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId == null || _userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilot Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      // Wrap the entire body in StreamBuilder to handle global state/status
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('groups/$_groupId/pilots/$_userId')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('Loading pilot data...'));
          }

          final pilotData = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map);
          
          final String status = pilotData['status']?.toString() ?? 'unknown';
          final String? retrieverId = pilotData['retrieverId']?.toString();
          
          // --- LOGIC IMPLEMENTATION ---
          
          // 1. "I Landed" Button Logic
          // Active ONLY if status is 'flying'
          final bool canSendLocation = (status == 'flying');

          // 2. "Call Retriever" Button Logic
          // Active ONLY if retrieverId is not null AND status is 'waiting'
          final bool canCallRetriever = (retrieverId != null && 
                                         retrieverId.isNotEmpty && 
                                         status == 'waiting');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. "I Landed" Action
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    // If loading, disable. If not flying, disable (null).
                    onPressed: (_isLoading || !canSendLocation) 
                        ? null 
                        : _sendLocation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.location_on),
                    label: Text(
                      _isLoading ? 'Sending...' : 'I Landed - Send Location',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
                
                // Optional: Status Indicator Text
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Current Status: $status",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),

                // 2. Retriever Info Section
                const Text(
                  "Assigned Retriever Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (retrieverId == null || retrieverId.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_empty,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                "Waiting for a retriever to be assigned...",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Retriever is assigned, show card
                      return _RetrieverInfoCard(
                        groupId: _groupId!,
                        retrieverId: retrieverId,
                        canCall: canCallRetriever,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RetrieverInfoCard extends StatelessWidget {
  final String groupId;
  final String retrieverId;
  final bool canCall;

  const _RetrieverInfoCard({
    required this.groupId,
    required this.retrieverId,
    required this.canCall,
  });

  Future<void> _callRetriever(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Could not launch $launchUri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance
          .ref('groups/$groupId/retrievers/$retrieverId')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading retriever info"));
        }

        if (!snapshot.hasData || snapshot.data?.value == null) {
          return const Center(child: Text("Retriever info not found."));
        }

        final data = Map<dynamic, dynamic>.from(snapshot.data!.value as Map);
        final name = data['nameSurname'] ?? 'Unknown Retriever';
        final phone = data['phoneNumber'];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_pin_circle,
                    size: 60, color: Colors.green),
                const SizedBox(height: 10),
                const Text(
                  "Your Retriever:",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (canCall && phone != null)
                        ? () => _callRetriever(phone)
                        : null,
                    icon: const Icon(Icons.phone),
                    label: const Text("Call Retriever"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

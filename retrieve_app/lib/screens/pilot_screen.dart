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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
          
          final bool canSendLocation = (status == 'flying');

          final bool canCallRetriever = (retrieverId != null && 
                                         retrieverId.isNotEmpty && 
                                         status == 'waiting');

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // STATUS CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: canSendLocation ? Colors.blue.shade50 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: canSendLocation ? Colors.blue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CURRENT STATUS", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // MASSIVE LANDED BUTTON
                GestureDetector(
                  onTap: (_isLoading || !canSendLocation) ? null : _sendLocation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: canSendLocation 
                          ? const LinearGradient(colors: [Colors.indigo, Colors.blueAccent], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: canSendLocation 
                          ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                           const CircularProgressIndicator(color: Colors.white)
                        else ...[
                           Icon(Icons.location_on_outlined, size: 60, color: canSendLocation ? Colors.white : Colors.grey.shade600),
                           const SizedBox(height: 16),
                           Text(
                             "I LANDED",
                             style: TextStyle(
                               fontSize: 32,
                               fontWeight: FontWeight.w900,
                               color: canSendLocation ? Colors.white : Colors.grey.shade600,
                               letterSpacing: 1.5,
                             ),
                           ),
                           Text(
                             "Tap to Send Location",
                             style: TextStyle(
                               fontSize: 16,
                               color: canSendLocation ? Colors.white70 : Colors.grey.shade600,
                             ),
                           ),
                        ]
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // RETRIEVER INFO
                if (retrieverId == null || retrieverId.isEmpty)
                  Center(
                    child: Text(
                      "Waiting for assignment...",
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  _RetrieverInfoCard(
                    groupId: _groupId!,
                    retrieverId: retrieverId,
                    canCall: canCallRetriever,
                  ),
                
                const SizedBox(height: 20),
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
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('groups/$groupId/retrievers/$retrieverId').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.value == null) {
          return const SizedBox.shrink();
        }

        final data = Map<dynamic, dynamic>.from(snapshot.data!.value as Map);
        final name = data['nameSurname'] ?? 'Unknown Retriever';
        final phone = data['phoneNumber'];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.person, color: Colors.green, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ASSIGNED RETRIEVER",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: (canCall && phone != null) ? () => _callRetriever(phone) : null,
                  style: IconButton.styleFrom(backgroundColor: canCall ? Colors.green : Colors.grey.shade300),
                  icon: const Icon(Icons.phone),
                  iconSize: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

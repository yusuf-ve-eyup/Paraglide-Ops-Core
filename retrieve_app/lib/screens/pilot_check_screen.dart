import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PilotCheckScreen extends StatefulWidget {
  const PilotCheckScreen({super.key});

  @override
  State<PilotCheckScreen> createState() => _PilotCheckScreenState();
}

class _PilotCheckScreenState extends State<PilotCheckScreen> {
  String? _groupId;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadGroupId();
    WakelockPlus.enable();
  }

  Future<void> _loadGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _groupId = prefs.getString('groupId');
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(
    String pilotId,
    String pilotName,
    bool isChecked,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final newStatus = isChecked ? 'befFly' : 'flying';
    final action = isChecked ? 'uncheck' : 'check';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to set $pilotName to ${isChecked ? "Inactive" : "Active"}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (mounted) FocusScope.of(context).unfocus();

    if (confirmed != true || _groupId == null) return;

    final dbRef = FirebaseDatabase.instance.ref('groups/$_groupId/pilots/$pilotId');

    if (newStatus == 'flying') {
      await dbRef.update({
        'status': newStatus,
        'wtsc': ServerValue.timestamp,
      });
    } else {
      await dbRef.update({
        'status': newStatus,
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer: $e')),
        );
      }
    }
  }

  void _showDetailDialog(Map<dynamic, dynamic> pilot, String pilotId) {
    FocusScope.of(context).unfocus();

    final name = pilot['nameSurname'] ?? 'Unknown';
    final phone = pilot['phoneNumber'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.badge, "Pilot ID", pilotId),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, "Phone", phone.toString().isNotEmpty ? phone : "N/A"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (phone.toString().isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _makePhoneCall(phone.toString());
                },
                icon: const Icon(Icons.call),
                label: const Text('Call Pilot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        );
      },
    ).then((_) {
       if(mounted) FocusScope.of(context).unfocus();
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pilotsRef = FirebaseDatabase.instance.ref('groups/$_groupId/pilots');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takeoff Checklist'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Search Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search Pilot Name...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            
            // Pilot List
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: pilotsRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No pilots found.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final rawData = snapshot.data!.snapshot.value;
                  final List<MapEntry<dynamic, dynamic>> pilotsList = [];

                  if (rawData is Map) {
                    pilotsList.addAll(rawData.entries);
                  } else if (rawData is List) {
                    for (int i = 0; i < rawData.length; i++) {
                      if (rawData[i] != null) {
                        pilotsList.add(MapEntry(i.toString(), rawData[i]));
                      }
                    }
                  }

                  final filteredPilots = pilotsList.where((entry) {
                    final pilot = entry.value as Map<dynamic, dynamic>;
                    final name = (pilot['nameSurname'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  filteredPilots.sort((a, b) {
                    final nameA = (a.value['nameSurname'] ?? '').toString();
                    final nameB = (b.value['nameSurname'] ?? '').toString();
                    return nameA.compareTo(nameB);
                  });

                  if (filteredPilots.isEmpty) {
                    return const Center(child: Text('No matching pilots found.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPilots.length,
                    itemBuilder: (context, index) {
                      final entry = filteredPilots[index];
                      final pilotId = entry.key;
                      final pilotData = entry.value as Map<dynamic, dynamic>;
                      final name = pilotData['nameSurname'] ?? 'Unknown';
                      final status = pilotData['status'];
                      
                      final isChecked = status != 'befFly';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isChecked ? Colors.green.withOpacity(0.5) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showDetailDialog(pilotData, pilotId),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isChecked ? Colors.green.shade100 : Colors.indigo.shade50,
                                  child: Icon(
                                    isChecked ? Icons.check : Icons.person_outline,
                                    color: isChecked ? Colors.green : Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        isChecked ? "Status: Active" : "Status: Inactive",
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: isChecked ? Colors.green : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    value: isChecked,
                                    activeColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (bool? value) {
                                      if (value != null) {
                                        _changeStatus(pilotId, name, isChecked);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

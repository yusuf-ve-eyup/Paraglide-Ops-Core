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
    // Unfocus any active element (like the search bar) before showing dialog or changing status
    // to prevent keyboard from popping up unexpectedly.
    FocusManager.instance.primaryFocus?.unfocus();

    // If currently checked (active), new status is 'befFly' (inactive).
    // If currently unchecked (inactive), new status is 'flying' (active).
    final newStatus = isChecked ? 'befFly' : 'flying';
    final action = isChecked ? 'uncheck' : 'check';

    // Show Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Status Change'),
          content: Text(
            'Are you sure you want to $action $pilotName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    // Ensure focus is cleared after dialog closes
    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    if (confirmed != true || _groupId == null) return;

    // Updated Path: groups/$groupId/pilots/$pilotId
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

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
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
    // Unfocus search bar if open
    FocusScope.of(context).unfocus();

    final name = pilot['nameSurname'] ?? 'Unknown';
    final phone = pilot['phoneNumber'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: $pilotId'),
              const SizedBox(height: 8),
              Text('Phone: $phone'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _makePhoneCall(phone.toString());
              },
              icon: const Icon(Icons.call),
              label: const Text('Call'),
            ),
          ],
        );
      },
    ).then((_) {
       // Ensure focus is cleared after dialog closes
       if(mounted) FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Updated Path: groups/$groupId/pilots
    final pilotsRef = FirebaseDatabase.instance.ref('groups/$_groupId/pilots');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takeoff Checklist'),
      ),
      // Detect taps outside input fields to dismiss keyboard
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search by Name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('No pilots found.'));
                  }

                  final rawData = snapshot.data!.snapshot.value;
                  final List<MapEntry<dynamic, dynamic>> pilotsList = [];

                  // Handle both Map and List (array) structures from Firebase
                  if (rawData is Map) {
                    pilotsList.addAll(rawData.entries);
                  } else if (rawData is List) {
                    for (int i = 0; i < rawData.length; i++) {
                      if (rawData[i] != null) {
                        // Use the index as the key, effectively converting List to Map entries
                        pilotsList.add(MapEntry(i.toString(), rawData[i]));
                      }
                    }
                  } else {
                     return const Center(child: Text('Unexpected data format'));
                  }

                  // Filter
                  final filteredPilots = pilotsList.where((entry) {
                    final pilot = entry.value as Map<dynamic, dynamic>;
                    final name =
                        (pilot['nameSurname'] ?? '').toString().toLowerCase();
                    
                    // Filter strictly by Name per new requirements
                    return name.contains(_searchQuery);
                  }).toList();

                  // Sort Alphabetically
                  filteredPilots.sort((a, b) {
                    final nameA = (a.value['nameSurname'] ?? '').toString();
                    final nameB = (b.value['nameSurname'] ?? '').toString();
                    return nameA.compareTo(nameB);
                  });

                  if (filteredPilots.isEmpty) {
                    return const Center(child: Text('No matching pilots.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filteredPilots.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = filteredPilots[index];
                      final pilotId = entry.key;
                      final pilotData = entry.value as Map<dynamic, dynamic>;

                      final name = pilotData['nameSurname'] ?? 'Unknown';
                      final status = pilotData['status'];
                      
                      // LOGIC UPDATE: Checkbox is checked if status is NOT 'befFly'
                      final isChecked = status != 'befFly';

                      return InkWell(
                        onTap: () => _showDetailDialog(pilotData, pilotId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left Side: Name
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Right Side: Checkbox
                              Transform.scale(
                                scale: 1.5,
                                child: Checkbox(
                                  value: isChecked,
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

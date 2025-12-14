import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'pilot_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _groupIdController = TextEditingController();
  final _userIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final groupId = _groupIdController.text.trim();
    final userId = _userIdController.text.trim();

    if (groupId.isEmpty || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseDatabase.instance;
      final prefs = await SharedPreferences.getInstance();

      // 1. Check Retriever
      final retrieverRef = db.ref('groups/$groupId/retrievers/$userId');
      final retrieverSnapshot = await retrieverRef.get();

      if (retrieverSnapshot.exists) {
        // Is Retriever
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userId);
        await prefs.setString('groupId', groupId);
        await prefs.setString('userType', 'retriever');
        
        // Save Name if available
        final data = retrieverSnapshot.value as Map?;
        if (data != null && data['nameSurname'] != null) {
             await prefs.setString('nameSurname', data['nameSurname']);
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        return;
      }

      // 2. Check Pilot (if not retriever)
      final pilotRef = db.ref('groups/$groupId/pilots/$userId');
      final pilotSnapshot = await pilotRef.get();

      if (pilotSnapshot.exists) {
        // Is Pilot
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userId);
        await prefs.setString('groupId', groupId);
        await prefs.setString('userType', 'pilot');
        
         // Save Name if available
        final data = pilotSnapshot.value as Map?;
        if (data != null && data['nameSurname'] != null) {
             await prefs.setString('nameSurname', data['nameSurname']);
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PilotScreen()),
          );
        }
        return;
      }

      // 3. Not found
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found in this Group.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _groupIdController,
                  decoration: const InputDecoration(
                    labelText: 'Group ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Submit'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

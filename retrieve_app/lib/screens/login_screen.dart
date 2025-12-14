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
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userId);
        await prefs.setString('groupId', groupId);
        await prefs.setString('userType', 'retriever');
        
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

      // 2. Check Pilot
      final pilotRef = db.ref('groups/$groupId/pilots/$userId');
      final pilotSnapshot = await pilotRef.get();

      if (pilotSnapshot.exists) {
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userId);
        await prefs.setString('groupId', groupId);
        await prefs.setString('userType', 'pilot');
        
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.paragliding, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Retriever Ops",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Floating Login Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _groupIdController,
                        decoration: const InputDecoration(
                          labelText: 'Group ID',
                          prefixIcon: Icon(Icons.group),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _userIdController,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("LOGIN"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

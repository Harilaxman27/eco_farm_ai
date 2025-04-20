import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// Corrected import paths
import 'auth/login_screen.dart';  // Ensure this file exists inside lib/auth/
import 'screens/farmer_home.dart'; // Ensure this file exists inside lib/screens/
import 'screens/buyer_home.dart';  // Ensure this file exists inside lib/screens/
import 'screens/dairy_farmer_home.dart';
import 'screens/poultry_farmer_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoFarmAI',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If no user is logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return LoginScreen();
        }

        // If user is logged in, check their role
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // If no user document found, return to login
              return LoginScreen();
            }

            final role = userSnapshot.data!.get('role') ?? '';
            Widget destination;

            switch (role) {
              case 'buyer':
                destination = BuyerHome();
                break;
              case 'crop_farmer':
                destination = FarmerHome();
                break;
              case 'dairy_farmer':
                destination = DairyFarmerHome();
                break;
              case 'poultry_farmer':
                destination = PoultryFarmerHome();
                break;
              default:
                destination = LoginScreen(); // fallback if role is invalid
            }

            return destination;
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'sign_in_page.dart';

void main() {
  runApp(const GiftSphereApp());
}

class GiftSphereApp extends StatelessWidget {
  const GiftSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GiftSphere',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
   
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Container(
              width: 225,
              height: 225,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/images/logo.png', 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
            
                  return Icon(
                    Icons.card_giftcard,
                    size: 100,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 40),
            
            // App Name
            const Text(
              'GiftSphere',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Loading indicator
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
  }
}
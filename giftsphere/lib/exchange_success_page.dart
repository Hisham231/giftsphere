import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضروري عشان ميزة النسخ (Clipboard)

class ExchangeSuccessPage extends StatelessWidget {
  final String eventCode; // أضفنا هذا المتغير لاستقبال الكود

  const ExchangeSuccessPage({super.key, required this.eventCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF7F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF53B175),
                  size: 80,
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Secret Gift Created!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Share this event code with your friends so they can join!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                ),
              ),
              
              const SizedBox(height: 30),

              // Event Code Box with Copy Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Column(
                  children: [
                    const Text('EVENT CODE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          eventCode, // عرض الكود هنا
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 5, color: Color(0xFFA35CFF)),
                        ),
                        const SizedBox(width: 15),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFFA35CFF)),
                          onPressed: () {
                            // نسخ الكود للحافظة
                            Clipboard.setData(ClipboardData(text: eventCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard!'),
                                backgroundColor: Color(0xFF53B175),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Back to Home Button
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    'Back to home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'otp_verification_page.dart';
import 'sign_up_page.dart'; 

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOTP() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 9) {
      _showError('Please enter a valid 9-digit phone number');
      return;
    }

    setState(() => _isLoading = true);

    // استدعاء الباكند
    final result = await ApiService.requestOTP(phone);

    if (!mounted) return; // حماية للـ Context
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationPage(
            phoneNumber: phone,
            // ✅ التعديل هنا: تمرير كود الديباج ليعرض فوراً
            initialDebugOtp: result['debug_otp']?.toString(), 
          ),
        ),
      );
    } else {
      _showError(result['message'] ?? 'Failed to send OTP');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              /// Logo Section
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png', 
                      height: 90, 
                      errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard, size: 80, color: Color(0xFF648DDB))
                    ),
                    const SizedBox(height: 16),
                    const Text('GiftSphere', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  ],
                ),
              ),

              const SizedBox(height: 60),
              const Text('Sign In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter your phone number to sign in or continue your setup.', style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 35),

              /// Input Phone field
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E1E1)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text('+966', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey.shade400),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 9,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: '5xxxxxxxx',
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF648DDB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 40),

              /// Create Account Section
              Center(
                child: Column(
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        'Create New Account',
                        style: TextStyle(
                          color: Color(0xFF648DDB),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
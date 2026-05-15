import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'otp_verification_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // فصل المتحكمات ليكون الاسم الأول والأخير منفصلين
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phone = _phoneController.text.trim();

    // التحقق من تعبئة جميع الخانات
    if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty) {
      _showMessage('Please fill all fields');
      return;
    }

    if (phone.length != 9) {
      _showMessage('Phone number must be 9 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // طلب رمز التحقق من الباكند
      final result = await ApiService.requestOTP(phone);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        // ننتقل لصفحة التحقق ونمرر الاسم الأول والأخير بدلاً من الاسم الكامل
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              phoneNumber: phone,
              firstName: firstName, // تمرير الاسم الأول
              lastName: lastName,   // تمرير الاسم الأخير
              initialDebugOtp: result['debug_otp']?.toString(), 
            ),
          ),
        );
      } else {
        _showMessage(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Network error, please try again');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            
            // خانة الاسم الأول
            const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                hintText: 'Enter your first name',
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 20),

            // خانة الاسم الأخير
            const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                hintText: 'Enter your last name',
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 20),
            
            // خانة رقم الجوال
            const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '5xxxxxxxx',
                // التعديل هنا: استخدمنا prefixIcon بدلاً من prefixText
                prefixIcon: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: Text(
                    '+966 ',
                    style: TextStyle(
                      color: Colors.black, // اللون اللي تحبه
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                    minWidth: 0, minHeight: 0), // عشان يضبط المسافات
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // زر التسجيل
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF648DDB), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
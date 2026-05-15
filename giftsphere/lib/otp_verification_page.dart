import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'home_page.dart';
import 'complete_profile_page.dart';
class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? initialDebugOtp;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.initialDebugOtp,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDebugOtp != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDebugSnackBar(widget.initialDebugOtp!);
      });
    }
  }

  void _showDebugSnackBar(String otp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('DEBUG: Your OTP is $otp'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String getOTP() => _otpControllers.map((c) => c.text).join();

  Future<void> verifyOTP() async {
    if (getOTP().length != 4 || _isLoading) return;
    
    setState(() => _isLoading = true);

    final result = await ApiService.verifyOTP(widget.phoneNumber, getOTP());
    
    if (!mounted) return;

    if (result['success']) {
      // ✅ تحديث الأسماء بشكل منفصل فور استلام التوكن
      if (widget.firstName != null && widget.lastName != null) {
        print('🔄 Updating names in background: ${widget.firstName} ${widget.lastName}');
        await ApiService.updateUserName(widget.firstName!, widget.lastName!);
      }
      
      setState(() => _isLoading = false);
      
      // الانتقال للصفحة الرئيسية وحذف جميع الصفحات السابقة من الذاكرة
final profileResult = await ApiService.getCurrentUserProfile();

if (!mounted) return;

bool needsProfileCompletion = true;

if (profileResult['success']) {
  final data = profileResult['data'];
  final firstName = data['first_name']?.toString().trim() ?? '';
  final lastName = data['last_name']?.toString().trim() ?? '';

  needsProfileCompletion = firstName.isEmpty || lastName.isEmpty;
}

if (needsProfileCompletion) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
    (route) => false,
  );
} else {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomePage()),
    (route) => false,
  );
}
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } // تم إغلاق الدالة هنا

  Future<void> resendOTP() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    final result = await ApiService.requestOTP(widget.phoneNumber);
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (result['success'] && result['debug_otp'] != null) {
      _showDebugSnackBar(result['debug_otp'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios), 
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 100),
              const Text('Check your SMS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Enter the 4-digit code sent to ${widget.phoneNumber}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 70, height: 56,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '', 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (v.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (getOTP().length == 4) {
                          verifyOTP();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF648DDB), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ) 
                      : const Text('Verify Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : resendOTP,
                  child: const Text(
                    'Didn\'t receive the SMS? Resend code', 
                    style: TextStyle(color: Color(0xFF648DDB), decoration: TextDecoration.underline),
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
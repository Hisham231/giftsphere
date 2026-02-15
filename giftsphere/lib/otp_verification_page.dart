import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'home_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  
  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4, // 4 digits to match Django OTP
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool isOTPComplete() {
    return getOTP().length == 4;
  }

  Future<void> verifyOTP() async {
    if (!isOTPComplete() || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    String otp = getOTP();
    print('🔄 Verifying OTP: $otp for ${widget.phoneNumber}');
    
    // Call Django API to verify OTP
    final result = await ApiService.verifyOTP(widget.phoneNumber, otp);
    
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      print('✅ OTP verification successful!');
      
      // Navigate to home page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // Remove all previous routes
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('❌ OTP verification failed: ${result['message']}');
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Invalid OTP'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Clear OTP fields on error
      for (var controller in _otpControllers) {
        controller.clear();
      }
      if (_focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> resendOTP() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    print('🔄 Resending OTP to ${widget.phoneNumber}');
    
    // Call Django API to resend OTP
    final result = await ApiService.requestOTP(widget.phoneNumber);
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    if (result['success']) {
      print('✅ OTP resent successfully');
      
      // Show debug OTP in development mode FIRST (more visible)
      if (result['debug_otp'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DEBUG: Your new OTP is ${result['debug_otp']}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      
      // Then show success message
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'OTP sent successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
      
      // Clear existing OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      if (_focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    } else {
      print('❌ Failed to resend OTP: ${result['message']}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
              
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(height: 111),
              
              // Title
              const Text(
                'Check your SMS',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 20,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.50,
                ),
              ),
              
              const SizedBox(height: 18),
              
              // Description
              const Text(
                'Enter the confirmation code that we sent you by SMS to your mobile number',
                style: TextStyle(
                  color: Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: -0.50,
                ),
              ),
              
              const SizedBox(height: 44),
              
              // OTP Input Boxes (4 digits)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 70,
                    height: 56,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                            color: Color(0xFFE1E1E1),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                            color: Color(0xFF648DDB),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                            color: Color(0xFFE1E1E1),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        setState(() {}); // Update button state
                        
                        // Auto-verify when all 4 digits are entered
                        if (isOTPComplete() && !_isLoading) {
                          // Small delay to show all digits before verifying
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (isOTPComplete() && !_isLoading) {
                              verifyOTP();
                            }
                          });
                        }
                      },
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 26),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (isOTPComplete() && !_isLoading) ? verifyOTP : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOTPComplete()
                        ? const Color(0xFF648DDB)
                        : const Color(0x66648DDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0x66648DDB),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.50,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 36),
              
              // Resend SMS
              Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Haven\'t got the SMS yet? ',
                        style: TextStyle(
                          color: Color(0xFF989898),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.50,
                        ),
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: _isLoading ? null : resendOTP,
                          child: Text(
                            'Resend SMS',
                            style: TextStyle(
                              color: _isLoading 
                                  ? const Color(0xFF989898)
                                  : const Color(0xFF648DDB),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              letterSpacing: -0.50,
                            ),
                          ),
                        ),
                      ),
                    ],
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
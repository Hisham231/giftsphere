import 'package:flutter/material.dart';
import 'api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  bool _isLoading = false;
  bool _isFetchingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  String _readValue(
    Map<String, dynamic>? serverData,
    Map<String, dynamic>? localData,
    String key,
  ) {
    final serverValue = serverData?[key]?.toString() ?? '';
    if (serverValue.trim().isNotEmpty) return serverValue;

    final localValue = localData?[key]?.toString() ?? '';
    return localValue;
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isFetchingProfile = true);

    final result = await ApiService.getCurrentUserProfile();
    final localData = await ApiService.getUserData();

    if (!mounted) return;

    Map<String, dynamic>? serverData;

    if (result['success'] == true && result['data'] != null) {
      serverData = Map<String, dynamic>.from(result['data']);
    }

    setState(() {
      _firstNameController.text =
          _readValue(serverData, localData, 'first_name');
      _lastNameController.text =
          _readValue(serverData, localData, 'last_name');

      _bankNameController.text =
          _readValue(serverData, localData, 'bank_name');
      _ibanController.text = _readValue(serverData, localData, 'iban');
      _accountHolderController.text =
          _readValue(serverData, localData, 'account_holder_name');

      _isFetchingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final bankName = _bankNameController.text.trim();
    final iban = _ibanController.text.trim().toUpperCase();
    final accountHolder = _accountHolderController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First name and last name are required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final hasAnyBankField =
        bankName.isNotEmpty || iban.isNotEmpty || accountHolder.isNotEmpty;

    final hasCompleteBankInfo =
        bankName.isNotEmpty && iban.isNotEmpty && accountHolder.isNotEmpty;

    if (hasAnyBankField && !hasCompleteBankInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all banking information fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final nameResult = await ApiService.updateUserName(
      firstName,
      lastName,
    );

    Map<String, dynamic>? bankingResult;

    if (hasCompleteBankInfo) {
      bankingResult = await ApiService.updateBankingInfo(
        bankName: bankName,
        iban: iban,
        accountHolderName: accountHolder,
      );
    } else {
      final existingUserData = await ApiService.getUserData() ?? {};
      final token = await ApiService.getToken();

      await ApiService.saveUserData({
        ...existingUserData,
        'first_name': firstName,
        'last_name': lastName,
        'token': token ?? existingUserData['token'],
      });
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    final nameSuccess = nameResult['success'] == true;
    final bankingSuccess =
        bankingResult == null || bankingResult['success'] == true;

    if (nameSuccess && bankingSuccess) {
      await ApiService.getCurrentUserProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bankingResult?['message'] ??
                nameResult['message'] ??
                'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF8F8FB),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isFetchingProfile
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFA35CFF),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _firstNameController,
                          decoration: _inputDecoration(label: 'First Name'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastNameController,
                          decoration: _inputDecoration(label: 'Last Name'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Banking Information',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Required if you want to create a Qattah.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _bankNameController,
                          decoration: _inputDecoration(
                            label: 'Bank Name',
                            hint: 'e.g. Al Rajhi Bank',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ibanController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration(
                            label: 'IBAN',
                            hint: 'SA...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _accountHolderController,
                          decoration: _inputDecoration(
                            label: 'Account Holder Name',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA35CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
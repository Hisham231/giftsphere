import 'package:flutter/material.dart';
import 'api_service.dart';
import 'receiver_wishlist_page.dart';

class MyAssignmentPage extends StatefulWidget {
  final int exchangeId;
  final String eventName;

  const MyAssignmentPage({
    super.key,
    required this.exchangeId,
    required this.eventName,
  });

  @override
  State<MyAssignmentPage> createState() => _MyAssignmentPageState();
}

class _MyAssignmentPageState extends State<MyAssignmentPage> {
  bool _isLoading = true;
  String? _receiverName;
  int? _receiverId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignment();
  }

  Future<void> _fetchAssignment() async {
    final result = await ApiService.getMyAssignment(widget.exchangeId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result['success']) {
        final receiver = result['data']['receiver'];

        if (receiver != null) {
          _receiverId = receiver['id'];

          final firstName = receiver['first_name']?.toString() ?? '';
          final lastName = receiver['last_name']?.toString() ?? '';
          final phone = receiver['phone_number']?.toString() ?? '';

          final fullName = '$firstName $lastName'.trim();

          _receiverName = fullName.isNotEmpty ? fullName : phone;
        } else {
          _errorMessage = 'Receiver information not found';
        }
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.eventName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFA35CFF),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          color: const Color(0xFF53B175).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          size: 52,
                          color: Color(0xFF53B175),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'You are gifting:',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Color(0xFFA35CFF),
                              size: 34,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _receiverName ?? 'Unknown',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA35CFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Check their wishlist to help you choose the perfect gift.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_receiverId != null && _receiverName != null)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReceiverWishlistPage(
                                    receiverId: _receiverId!,
                                    receiverName: _receiverName!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'View Wishlist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF648DDB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'exchange_success_page.dart';
import 'api_service.dart';

class ExchangeEventDetails extends StatefulWidget {
  final List<Map<String, dynamic>> selectedParticipants;

  const ExchangeEventDetails({super.key, required this.selectedParticipants});

  @override
  State<ExchangeEventDetails> createState() => _ExchangeEventDetailsState();
}

class _ExchangeEventDetailsState extends State<ExchangeEventDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _createEvent() async {
    if (_nameController.text.isEmpty || _budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double budget = double.tryParse(_budgetController.text) ?? 0.0;

      // ✅ الإصلاح هنا: نستخدم widget.selectedParticipants
      List<int> participantIds = widget.selectedParticipants
          .map((u) => int.parse(u['id'].toString()))
          .toList();

      final result = await ApiService.createExchange(
        _nameController.text, 
        budget, 
        participantIds
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {

      final String generatedCode = result['data']['invite_code'].toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExchangeSuccessPage(eventCode: generatedCode),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error occurred'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: const [
                        Text('Secret Exchange', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        Text('Set Rules', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E2E2)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Event name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'enter event name',
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Set budget (SAR)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'enter budget',
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text('Selected participants', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...widget.selectedParticipants.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEEEDED),
                        child: Text(p['name'][0], style: const TextStyle(color: Colors.black)),
                      ),
                      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(25),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA35CFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Secret Exchange Event', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}
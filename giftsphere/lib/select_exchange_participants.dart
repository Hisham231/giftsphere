import 'package:flutter/material.dart';
import 'exchange_event_details.dart';

class SelectExchangeParticipants extends StatefulWidget {
  const SelectExchangeParticipants({super.key});

  @override
  State<SelectExchangeParticipants> createState() => _SelectExchangeParticipantsState();
}

class _SelectExchangeParticipantsState extends State<SelectExchangeParticipants> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  // Sample contacts
  final List<Map<String, dynamic>> allContacts = [
    {'name': 'Ahmed', 'phone': '+966501234567', 'selected': false},
    {'name': 'Mohammed', 'phone': '+966509876543', 'selected': false},
    {'name': 'Khalid', 'phone': '+966505555555', 'selected': false},
    {'name': 'Saud', 'phone': '+966507777777', 'selected': false},
    {'name': 'Abdullah', 'phone': '+966506666666', 'selected': false},
    {'name': 'Majed', 'phone': '+966508888888', 'selected': false},
  ];

  List<Map<String, dynamic>> filteredContacts = [];

  @override
  void initState() {
    super.initState();
    filteredContacts = List.from(allContacts);
  }

  void _filterContacts(String query) {
    setState(() {
      filteredContacts = allContacts.where((contact) {
        return contact['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _toggleContact(int index) {
    setState(() {
      final contact = filteredContacts[index];
      final allIndex = allContacts.indexWhere((c) => c['name'] == contact['name']);
      allContacts[allIndex]['selected'] = !allContacts[allIndex]['selected'];
      filteredContacts[index]['selected'] = allContacts[allIndex]['selected'];
    });
  }

  void _nextStep() {
    final selected = allContacts.where((c) => c['selected'] == true).toList();
    if (selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 participants for an exchange'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExchangeEventDetails(selectedParticipants: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = allContacts.where((c) => c['selected'] == true).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        Text(
                          'Secret Exchange',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Select participants',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E2E2)),

            // Search
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterContacts,
                  decoration: const InputDecoration(
                    hintText: 'Search by name',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Contacts List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  final isSelected = contact['selected'];
                  return ListTile(
                    onTap: () => _toggleContact(index),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEEEDED),
                      child: Text(contact['name'][0], style: const TextStyle(color: Colors.black)),
                    ),
                    title: Text(contact['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Color(0xFFA35CFF))
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Sheet Button
      bottomSheet: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedCount >= 2 ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA35CFF),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Next Step ($selectedCount)',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
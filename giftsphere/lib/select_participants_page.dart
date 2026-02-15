import 'package:flutter/material.dart';
import 'group_gift_details_page.dart';

class SelectParticipantsPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  
  const SelectParticipantsPage({
    super.key,
    required this.cartItems,
  });

  @override
  State<SelectParticipantsPage> createState() => _SelectParticipantsPageState();
}

class _SelectParticipantsPageState extends State<SelectParticipantsPage> {
  int _selectedIndex = 2; // Favourite tab selected
  final TextEditingController _searchController = TextEditingController();
  
  // Sample contacts
  final List<Map<String, dynamic>> allContacts = [
    {'name': 'Ahmed', 'phone': '+966501234567', 'selected': false},
    {'name': 'Mohammed', 'phone': '+966509876543', 'selected': false},
    {'name': 'Khalid', 'phone': '+966505555555', 'selected': false},
    {'name': 'Saud', 'phone': '+966507777777', 'selected': false},
    {'name': 'Abdullah', 'phone': '+966506666666', 'selected': false},
    {'name': 'Majed', 'phone': '+966508888888', 'selected': false},
    {'name': 'Fahad', 'phone': '+966504444444', 'selected': false},
    {'name': 'Turki', 'phone': '+966503333333', 'selected': false},
  ];
  
  List<Map<String, dynamic>> filteredContacts = [];
  
  @override
  void initState() {
    super.initState();
    filteredContacts = List.from(allContacts);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredContacts = List.from(allContacts);
      } else {
        filteredContacts = allContacts.where((contact) {
          return contact['name'].toLowerCase().contains(query.toLowerCase()) ||
                 contact['phone'].contains(query);
        }).toList();
      }
    });
  }

  void _toggleContact(int index) {
    setState(() {
      // Find the contact in allContacts
      final contact = filteredContacts[index];
      final allIndex = allContacts.indexWhere((c) => c['name'] == contact['name']);
      allContacts[allIndex]['selected'] = !allContacts[allIndex]['selected'];
      filteredContacts[index]['selected'] = allContacts[allIndex]['selected'];
    });
  }

  List<Map<String, dynamic>> _getSelectedParticipants() {
    return allContacts
        .where((contact) => contact['selected'] == true)
        .map((contact) => {
          'name': contact['name']?.toString() ?? 'Unknown',
          'phone': contact['phone']?.toString() ?? '',
        })
        .toList();
  }

  void _proceedToDetails() {
    final selectedParticipants = _getSelectedParticipants();
    
    if (selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one participant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to group gift details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupGiftDetailsPage(
          cartItems: widget.cartItems,
          selectedParticipants: selectedParticipants,
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _getSelectedParticipants().length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 11),
              color: const Color(0xFFE2E2E2),
            ),
            
            // Search Bar
            _buildSearchBar(),
            
            const SizedBox(height: 16),
            
            // Selected count
            if (selectedCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Color(0xFF6366F1), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '$selectedCount participant${selectedCount > 1 ? 's' : ''} selected',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Contacts List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  return _buildContactItem(index);
                },
              ),
            ),
          ],
        ),
      ),
      
      // Next Step Button
      bottomSheet: _buildBottomSheet(selectedCount),
      
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Select Participants',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Who will contribute?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or phone',
            hintStyle: TextStyle(
              color: const Color(0xFF9F9F9F),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF9F9F9F),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: _filterContacts,
        ),
      ),
    );
  }

  Widget _buildContactItem(int index) {
    final contact = filteredContacts[index];
    final isSelected = contact['selected'] == true;
    
    return GestureDetector(
      onTap: () => _toggleContact(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF6366F1).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E2E2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFE8EBF5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact['name'][0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact['phone'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF6366F1) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E2E2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(int selectedCount) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: selectedCount > 0 ? _proceedToDetails : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedCount > 0 
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              selectedCount > 0
                  ? 'Next Step ($selectedCount selected)'
                  : 'Select Participants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x7FE6EAF3),
            blurRadius: 37,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home, 'Home'),
          _buildNavItem(1, Icons.shopping_cart, 'Cart'),
          _buildNavItem(2, Icons.favorite, 'Favourite'),
          _buildNavItem(3, Icons.person, 'Account'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF53B175) : const Color(0xFF030303),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF53B175) : const Color(0xFF030303),
              fontSize: 12,
              fontFamily: 'Gilroy',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
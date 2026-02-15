import 'package:flutter/material.dart';

class GroupGiftDetailsPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final List<Map<String, dynamic>> selectedParticipants;
  
  const GroupGiftDetailsPage({
    super.key,
    required this.cartItems,
    required this.selectedParticipants,
  });

  @override
  State<GroupGiftDetailsPage> createState() => _GroupGiftDetailsPageState();
}

class _GroupGiftDetailsPageState extends State<GroupGiftDetailsPage> {
  int _selectedIndex = 2; // Favourite tab selected
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigate based on index
    if (index == 0) {
      // Go to home
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      // Go back to cart
      Navigator.popUntil(context, (route) => route.settings.name == '/cart' || route.isFirst);
    }
  }

  void _createGroupGift() {
    String recipientName = _nameController.text.trim();
    String recipientPhone = _phoneController.text.trim();
    
    // Validation
    if (recipientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (recipientPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Success - Create group gift
    print('Creating group gift for: $recipientName');
    print('Phone: $recipientPhone');
    print('Participants: ${widget.selectedParticipants.map((p) => p['name']).join(', ')}');
    print('Cart items: ${widget.cartItems.length}');
    
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Text('Group gift created for $recipientName'),
        actions: [
          TextButton(
            onPressed: () {
              // Go back to home/cart
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: const Color(0xFFFCFCFC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      // Selected Gift Section
                      _buildSelectedGiftSection(),
                      
                      // Divider
                      Container(
                        height: 1,
                        margin: const EdgeInsets.fromLTRB(25, 16, 25, 16),
                        color: const Color(0xFFE2E2E2),
                      ),
                      
                      // Selected Participants Section
                      _buildSelectedParticipantsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Gift For Section
                      _buildGiftForSection(),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Stack with Button and Navigation
      bottomSheet: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Create Group Gift Button
          Container(
            color: const Color(0xFFFCFCFC),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildCreateButton(),
          ),
          // Bottom Navigation Bar
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              'Group Gift',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildSelectedGiftSection() {
    if (widget.cartItems.isEmpty) return const SizedBox();
    
    final firstItem = widget.cartItems[0];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              'Selected Gift',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          // Gift Item Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 73,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    (firstItem['image'] != null && firstItem['image'].toString().isNotEmpty)
                        ? firstItem['image']
                        : 'https://via.placeholder.com/73x88',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.card_giftcard,
                          size: 30,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    
                    // Product Name
                    Text(
                      firstItem['name'] ?? 'Product',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Reddit Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Product Description
                    Text(
                      firstItem['description'] ?? 'Description',
                      style: TextStyle(
                        color: const Color(0xFF717171),
                        fontSize: 12,
                        fontFamily: 'Reddit Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quantity Display
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 27,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Text(
                          '${firstItem['quantity'] ?? 1}',
                          style: TextStyle(
                            color: const Color(0xFF181725),
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Container(
                          width: 32,
                          height: 27,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E2E2)),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Color(0xFF53B175),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price
              Padding(
                padding: const EdgeInsets.only(top: 66),
                child: Text(
                  '${firstItem['price'] ?? 0} SAR ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Reddit Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedParticipantsSection() {
    // Safety check for participants list
    if (widget.selectedParticipants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: Text(
            'No participants selected',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              'Selected participants',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          // Participants List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.selectedParticipants.length,
            itemBuilder: (context, index) {
              final participant = widget.selectedParticipants[index];
              // Additional safety check
              if (participant == null) return SizedBox.shrink();
              return _buildParticipantItem(participant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(Map<String, dynamic> participant) {
    // Safe extraction of participant name with proper null handling
    final String participantName = participant['name']?.toString() ?? 'Unknown';
    
    // Generate initial from name
    String initial = participantName.isNotEmpty 
        ? participantName[0].toUpperCase() 
        : 'U';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Avatar with initial
            Container(
              width: 39,
              height: 39,
              decoration: const BoxDecoration(
                color: Color(0xFFEEEDED),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Name
            Expanded(
              child: Text(
                participantName,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftForSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 9, bottom: 8),
            child: Text(
              'Gift for:',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          // Name Input Field
          Container(
            height: 53,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x26000000),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'enter name',
                hintStyle: TextStyle(
                  color: const Color(0xFF848484),
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Phone Number Label
          Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 8),
            child: Text(
              'Phone Number',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          // Phone Input Field
          Container(
            height: 53,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x26000000),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'enter phone number',
                hintStyle: TextStyle(
                  color: const Color(0xFF888888),
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 67,
      child: ElevatedButton(
        onPressed: _createGroupGift,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA35CFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          elevation: 0,
        ),
        child: Text(
          'Create Group Gift',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
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
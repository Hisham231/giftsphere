import 'package:flutter/material.dart';
import 'group_gift_page.dart';
import 'select_participants_page.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialItems;
  
  const CartPage({super.key, this.initialItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int _selectedIndex = 1; // Cart is selected
  late List<Map<String, dynamic>> cartItems;

  @override
  void initState() {
    super.initState();
    // Use initial items or default
    cartItems = widget.initialItems ?? [
      {
        'name': 'Apple iPhone 17 Pro Max',
        'description': '5G, 256GB, Deep Blue',
        'price': 5499.0,
        'quantity': 1,
        'image': 'https://via.placeholder.com/150',
      },
    ];
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigate based on index
    if (index == 0) {
      Navigator.pop(context); // Go back to home
    }
  }

  void _incrementQuantity(int index) {
    setState(() {
      cartItems[index]['quantity']++;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (cartItems[index]['quantity'] > 1) {
        cartItems[index]['quantity']--;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item removed from cart'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  void _createGroupGift() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to Select Participants Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectParticipantsPage(cartItems: cartItems),
      ),
    );
  }

  void _checkout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implement checkout
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checkout feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: cartItems.isEmpty
            ? _buildEmptyCart()
            : Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 11),
                    color: const Color(0xFFE2E2E2),
                  ),
                  
                  // Cart Items List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(25),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(index);
                      },
                    ),
                  ),
                  
                  // Bottom Section with Buttons
                  _buildBottomSection(),
                ],
              ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Add some products to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupGiftPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'My Cart',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = cartItems[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 73,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image'] ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Expanded(
                      child: Text(
                        item['name'],
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Reddit Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                    
                    // Remove Button
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      onPressed: () => _removeItem(index),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 5),
                
                // Description
                Text(
                  item['description'],
                  style: TextStyle(
                    color: const Color(0xFF7C7C7C),
                    fontSize: 12,
                    fontFamily: 'Reddit Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Quantity Controls and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E2E2)),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        children: [
                          // Minus Button
                          GestureDetector(
                            onTap: () => _decrementQuantity(index),
                            child: Container(
                              width: 35,
                              height: 35,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: const Color(0xFF7C7C7C),
                              ),
                            ),
                          ),
                          
                          // Quantity
                          Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            child: Text(
                              '${item['quantity']}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Reddit Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          // Plus Button
                          GestureDetector(
                            onTap: () => _incrementQuantity(index),
                            child: Container(
                              width: 35,
                              height: 35,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: const Color(0xFF53B175),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Price
                    Text(
                      '${(item['price'] * item['quantity']).toStringAsFixed(0)} SAR',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Reddit Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkout Button (Green)
          SizedBox(
            width: double.infinity,
            height: 67,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53B175),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Go to Checkout',
                    style: TextStyle(
                      color: const Color(0xFFFCFCFC),
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF489E67),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_calculateTotal().toStringAsFixed(0)} SAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Create Group Gift Button (Purple)
          SizedBox(
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
                  color: const Color(0xFFFCFCFC),
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
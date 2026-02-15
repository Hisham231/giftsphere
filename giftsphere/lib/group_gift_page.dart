import 'package:flutter/material.dart';
import 'api_service.dart';
import 'cart_page.dart';

class GroupGiftPage extends StatefulWidget {
  const GroupGiftPage({super.key});

  @override
  State<GroupGiftPage> createState() => _GroupGiftPageState();
}

class _GroupGiftPageState extends State<GroupGiftPage> {
  int _selectedIndex = 2; // Favourite tab selected
  List<dynamic> _products = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _selectedProducts = []; // Cart items

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getProducts();

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _products = result['products'];
      }
    });
  }

  void _addToCart(dynamic product) {
    setState(() {
      // Check if product already in cart
      final existingIndex = _selectedProducts.indexWhere(
        (item) => item['id'] == product['id']
      );

      if (existingIndex >= 0) {
        // Increase quantity
        _selectedProducts[existingIndex]['quantity']++;
      } else {
        // Add new product
        _selectedProducts.add({
          'id': product['id'],
          'name': product['name'],
          'description': product['description'],
          'price': double.parse(product['price'].toString()),
          'quantity': 1,
          'image': product['image_url'],
        });
      }
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: _goToCart,
        ),
      ),
    );
  }

  void _goToCart() {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your cart is empty. Add some products first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to cart with selected products
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(initialItems: _selectedProducts),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pop(context); // Go back to home
    } else if (index == 1) {
      _goToCart(); // Go to cart
    }
  }

  List<dynamic> _getProductsByCategory(int categoryId) {
    return _products.where((p) => p['category'] == categoryId).toList();
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

            // Search Bar
            _buildSearchBar(),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No products available',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Featured Products
                              _buildProductSection(
                                'Featured',
                                _products.take(4).toList(),
                              ),

                              const SizedBox(height: 24),

                              // Electronics (category 5)
                              _buildProductSection(
                                'Electronics',
                                _getProductsByCategory(5),
                              ),

                              const SizedBox(height: 24),

                              // Perfumes (category 6)
                              _buildProductSection(
                                'Perfumes',
                                _getProductsByCategory(6),
                              ),

                              const SizedBox(height: 24),

                              // Auto Parts (category 7)
                              _buildProductSection(
                                'Auto Parts',
                                _getProductsByCategory(7),
                              ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),

      // Floating Cart Button
      floatingActionButton: _selectedProducts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _goToCart,
              backgroundColor: const Color(0xFF6366F1),
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Cart (${_selectedProducts.length})',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,

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
                  'Group Gift',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Select Gift',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
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
            hintText: 'search for a product',
            hintStyle: TextStyle(
              color: const Color(0xFF9F9F9F),
              fontSize: 14,
              fontFamily: 'Questrial',
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
          onChanged: (value) {
            // TODO: Implement search
          },
        ),
      ),
    );
  }

  Widget _buildProductSection(String title, List<dynamic> products) {
    if (products.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.25,
                  ),
                ),
                Text(
                  'view all',
                  style: TextStyle(
                    color: const Color(0xFF858585),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Products Grid
          SizedBox(
            height: 260, // Increased from 240
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final isInCart = _selectedProducts.any((item) => item['id'] == product['id']);
    
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isInCart ? Border.all(color: Color(0xFF6366F1), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey.shade100,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Image.network(
                      product['image_url'] ?? 'https://via.placeholder.com/150',
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.card_giftcard,
                          size: 50,
                          color: Colors.grey.shade400,
                        );
                      },
                    ),
                  ),
                  // Add button
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isInCart ? Colors.green : const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInCart ? Icons.check : Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    product['name'] ?? 'Product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1B1B1B),
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Description
                  Text(
                    product['description'] ?? 'Description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF979797),
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Price
                  Text(
                    '${product['price']} SAR',
                    style: TextStyle(
                      color: const Color(0xFF1B1B1B),
                      fontSize: 15,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF53B175) : const Color(0xFF030303),
                size: 24,
              ),
              if (index == 1 && _selectedProducts.isNotEmpty)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_selectedProducts.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
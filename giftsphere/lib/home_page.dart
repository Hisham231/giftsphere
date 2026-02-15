import 'package:flutter/material.dart';
import 'package:giftsphere/cart_page.dart';
import 'package:giftsphere/group_gift_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // First row recipients
  final List<Map<String, String>> firstRowRecipients = [
    {'name': 'Father', 'image': 'assets/images/father.jpeg'},
    {'name': 'Husband', 'image': 'assets/images/husband.png'},
    {'name': 'Friends', 'image': 'assets/images/friends.png'},
    {'name': 'Grandfather', 'image': 'assets/images/grandfather.png'},
    {'name': 'Uncle', 'image': 'assets/images/uncle.png'},
    {'name': 'Children', 'image': 'assets/images/children.png'},
  ];

  // Second row recipients
  final List<Map<String, String>> secondRowRecipients = [
    {'name': 'Mother', 'image': 'assets/images/mother.png'},
    {'name': 'Wife', 'image': 'assets/images/wife.png'},
    {'name': 'Colleague', 'image': 'assets/images/colleague.png'},
    {'name': 'Grandmother', 'image': 'assets/images/grandmother.png'},
    {'name': 'Aunt', 'image': 'assets/images/aunt.png'},
  ];

  // Services list generator (needs context for navigation)
  List<Map<String, dynamic>> _getServices() {
    return [
      {
        'title': 'Group Gift',
        'image': 'https://via.placeholder.com/64x69',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupGiftPage()),
          );
        },
      },
      {
        'title': 'Gift Quiz',
        'image': 'https://via.placeholder.com/58x69',
        'onTap': () => print('Gift Quiz tapped'),
      },
      {
        'title': 'Secret exchange',
        'image': 'https://via.placeholder.com/58x69',
        'onTap': () => print('Secret exchange tapped'),
      },
    ];
  }
  
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 1) {
      // Navigate to Cart page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 20),
              
              // Image Carousel (Admin Ads)
              _buildImageCarousel(),
              
              const SizedBox(height: 20),
              
              // Services Section
              _buildServicesSection(),
              
              const SizedBox(height: 20),
              
              // "Who is the gift for?" Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Who is the gift for?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // First Row - Recipients
              _buildHorizontalRecipientsList(firstRowRecipients),
              
              const SizedBox(height: 15),
              
              // Second Row - Recipients
              _buildHorizontalRecipientsList(secondRowRecipients),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'GiftSphere',
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 20,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: PageView(
        children: [
          _buildCarouselItem('https://via.placeholder.com/229x229'),
          _buildCarouselItem('https://via.placeholder.com/266x230'),
          _buildCarouselItem('https://via.placeholder.com/230x230'),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _getServices().map((service) {
              return _buildServiceCard(
                service['title'],
                service['image'],
                service['onTap'],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 121,
        height: 109,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              width: 64,
              height: 69,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.card_giftcard,
                  size: 50,
                  color: const Color(0xFF648DDB),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalRecipientsList(List<Map<String, String>> items) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildRecipientCard(
            items[index]['name']!,
            items[index]['image']!,
          );
        },
      ),
    );
  }

  Widget _buildRecipientCard(String name, String imagePath) {
    return GestureDetector(
      onTap: () {
        print('Selected: $name');
        // TODO: Navigate to gift selection page for this recipient
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            // Image Circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image doesn't exist
                    return Icon(
                      Icons.person,
                      size: 40,
                      color: const Color(0xFF648DDB),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Name
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1D1E20),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
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
          _buildNavItem(2, Icons.store, 'Market'),
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
              fontFamily: 'Questrial',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
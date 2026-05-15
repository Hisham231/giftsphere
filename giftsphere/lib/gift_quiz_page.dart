import 'package:flutter/material.dart';
import 'api_service.dart';
import 'cart_page.dart';

class GiftQuizPage extends StatefulWidget {
  const GiftQuizPage({super.key});

  @override
  State<GiftQuizPage> createState() => _GiftQuizPageState();
}

class _GiftQuizPageState extends State<GiftQuizPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();

  String? _selectedOccasion;
  String? _selectedGender;

  bool _isLoading = false;
  bool _hasSubmitted = false;
  List<dynamic> _recommendedProducts = [];

  final List<Map<String, String>> _occasions = [
    {'label': 'Birthday', 'value': 'birthday'},
    {'label': 'Graduation', 'value': 'graduation'},
    {'label': 'Eid', 'value': 'eid'},
    {'label': 'Wedding', 'value': 'wedding'},
    {'label': 'Anniversary', 'value': 'anniversary'},
  ];

  final List<Map<String, String>> _genders = [
    {'label': 'Male', 'value': 'male'},
    {'label': 'Female', 'value': 'female'},
    {'label': 'Any', 'value': 'any'},
  ];

  final List<String> _quickInterests = [
    'tech',
    'beauty',
    'games',
    'books',
    'home',
    'practical',
    'fitness',
    'office',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _interestController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

 Future<void> _submitQuiz() async {
  final age = _ageController.text.trim();
  final interests = _interestController.text.trim();
  final minBudget = _minBudgetController.text.trim();
  final maxBudget = _maxBudgetController.text.trim();

  if (_selectedOccasion == null ||
      _selectedGender == null ||
      age.isEmpty ||
      interests.isEmpty ||
      minBudget.isEmpty ||
      maxBudget.isEmpty) {
    _showSnackBar('Please complete all quiz fields.', Colors.orange);
    return;
  }

  setState(() {
    _isLoading = true;
    _hasSubmitted = true;
    _recommendedProducts = [];
  });

  final result = await ApiService.takeGiftQuiz(
    occasion: _selectedOccasion!,
    recipientAge: age,
    recipientGender: _selectedGender!,
    interests: interests,
    budgetMin: minBudget,
    budgetMax: maxBudget,
  );

  if (!mounted) return;

  setState(() {
    _isLoading = false;
    if (result['success']) {
      _recommendedProducts = result['products'] ?? [];
    }
  });

  if (!result['success']) {
    _showSnackBar(result['message'] ?? 'Failed to get recommendations.', Colors.red);
  }
}

  Future<void> _addToCart(Map<String, dynamic> product) async {
    await ApiService.addToCart(product);

    if (!mounted) return;

    _showSnackBar('Added to cart', const Color(0xFF53B175));
  }

  Future<void> _addToWishlist(int productId) async {
    final wishResult = await ApiService.getWishlists();

    int? wishlistId;

    if (wishResult['success'] && wishResult['data'].isNotEmpty) {
      wishlistId = wishResult['data'][0]['id'];
    } else {
      final createResult = await ApiService.createWishlist('My Wishlist');
      if (createResult['success']) {
        wishlistId = createResult['data']['id'];
      }
    }

    if (wishlistId == null) {
      _showSnackBar('Could not find wishlist.', Colors.red);
      return;
    }

    final result = await ApiService.addToWishlist(productId, wishlistId);

    if (!mounted) return;

    if (result['success']) {
      _showSnackBar('Added to wishlist', const Color(0xFFA35CFF));
    } else {
      _showSnackBar(result['message'] ?? 'Failed to add to wishlist', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  String _categoryName(dynamic category) {
    if (category == null) return 'Gift';
    if (category is Map && category['name'] != null) {
      return category['name'].toString();
    }
    return category.toString();
  }

  Widget _buildChoiceChips({
    required List<Map<String, String>> items,
    required String? selectedValue,
    required void Function(String value) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedValue == item['value'];

        return ChoiceChip(
          label: Text(item['label']!),
          selected: isSelected,
          selectedColor: const Color(0xFFA35CFF).withOpacity(0.18),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFFA35CFF) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) => onSelected(item['value']!),
        );
      }).toList(),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF648DDB)),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildQuizForm() {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about the recipient 🎁',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Answer a few questions and we will recommend matching gifts.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 22),

          const Text(
            'Occasion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          _buildChoiceChips(
            items: _occasions,
            selectedValue: _selectedOccasion,
            onSelected: (value) {
              setState(() => _selectedOccasion = value);
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Recipient Gender',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          _buildChoiceChips(
            items: _genders,
            selectedValue: _selectedGender,
            onSelected: (value) {
              setState(() => _selectedGender = value);
            },
          ),

          const SizedBox(height: 20),

          _buildInput(
            controller: _ageController,
            label: 'Recipient Age',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          _buildInput(
            controller: _interestController,
            label: 'Interest, e.g. tech, beauty, games',
            icon: Icons.interests_outlined,
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickInterests.map((interest) {
              return ActionChip(
                label: Text(interest),
                backgroundColor: const Color(0xFFF5F6FA),
                onPressed: () {
                  setState(() {
                    _interestController.text = interest;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _minBudgetController,
                  label: 'Min Budget',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  controller: _maxBudgetController,
                  label: 'Max Budget',
                  icon: Icons.savings_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF648DDB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                      'Show Recommendations',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final int productId = product['id'];
    final String name = product['name']?.toString() ?? 'Unknown Product';
    final String imageUrl = product['image_url']?.toString() ?? '';
    final String price = product['price']?.toString() ?? '0';
    final String storeName = product['store_name']?.toString() ?? 'Store';
    final String category = _categoryName(product['category']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(16),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? const Icon(Icons.card_giftcard, size: 42, color: Color(0xFFA35CFF))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$category • $storeName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'SAR $price',
                  style: const TextStyle(
                    color: Color(0xFF648DDB),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53B175),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cart',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _addToWishlist(productId),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 22,
                        ),
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

  Widget _buildResultsSection() {
    if (!_hasSubmitted) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_recommendedProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 58, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No matching gifts found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing the budget, interest, or occasion.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Gifts (${_recommendedProducts.length})',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._recommendedProducts.map((product) {
            return _buildProductCard(Map<String, dynamic>.from(product));
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Gift Quiz',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            _buildQuizForm(),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }
}
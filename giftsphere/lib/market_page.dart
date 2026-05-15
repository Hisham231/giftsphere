import 'package:flutter/material.dart';
import 'api_service.dart';
import 'my_wishlist_page.dart';
import 'cart_page.dart';

class MarketPage extends StatefulWidget {
  final String? initialOccasion;
  final String? initialTargetGender;
  final String? initialRecipientAge;
  final String? initialInterests;
  final String? initialTitle;

  const MarketPage({
    super.key,
    this.initialOccasion,
    this.initialTargetGender,
    this.initialRecipientAge,
    this.initialInterests,
    this.initialTitle,
  });

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  List<dynamic> _products = [];
  List<int> _wishlistedProductIds = [];
  int? _myWishlistId;
  bool _isLoading = true;

  // 🔍 متغير البحث
  final TextEditingController _searchController = TextEditingController();

  // 🎛️ متغيرات الفلاتر
  String? _selectedCategory;
  String? _selectedOccasion;
  String? _selectedGender;
  String? _selectedRecipientAge;
  String? _selectedInterests;
  List<Map<String, dynamic>> _cartItems = [];
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Electronics', 'icon': Icons.devices},
    {'name': 'Perfumes', 'icon': Icons.spa},
    {'name': 'Books', 'icon': Icons.menu_book},
    {'name': 'Games', 'icon': Icons.sports_esports},
    {'name': 'Accessories', 'icon': Icons.watch},
    {'name': 'Gift Cards', 'icon': Icons.card_giftcard},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Home & Lifestyle', 'icon': Icons.home},
  ];

  final List<String> _occasions = [
    'Birthday',
    'Anniversary',
    'Graduation',
    'Wedding',
    'Eid',
  ];

  final List<String> _genders = [
    'Male',
    'Female',
    'Kids',
    'Unisex',
  ];


  String? _displayOccasionValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    switch (value.toLowerCase()) {
      case 'birthday':
        return 'Birthday';
      case 'graduation':
        return 'Graduation';
      case 'eid':
        return 'Eid';
      case 'wedding':
        return 'Wedding';
      case 'anniversary':
        return 'Anniversary';
      default:
        return value;
    }
  }

  String? _displayGenderValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    switch (value.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'any':
      case 'unisex':
        return 'Unisex';
      case 'kids':
        return 'Kids';
      default:
        return value;
    }
  }

  String? _apiOccasionValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.toLowerCase();
  }

  String? _apiGenderValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final lower = value.toLowerCase();

    if (lower == 'unisex' || lower == 'kids') {
      return 'any';
    }

    return lower;
  }

  String _activeFiltersText() {
    final filters = <String>[];

    if (_selectedOccasion != null) {
      filters.add('Occasion: $_selectedOccasion');
    }

    if (_selectedGender != null) {
      filters.add('For: $_selectedGender');
    }

    if (_selectedRecipientAge != null) {
      filters.add('Age: $_selectedRecipientAge');
    }

    if (_selectedInterests != null) {
      filters.add('Interests: $_selectedInterests');
    }

    if (_selectedCategory != null) {
      filters.add('Category: $_selectedCategory');
    }

    return filters.join(' • ');
  }

  @override
  void initState() {
    super.initState();

    _selectedOccasion = _displayOccasionValue(widget.initialOccasion);
    _selectedGender = _displayGenderValue(widget.initialTargetGender);
    _selectedRecipientAge = widget.initialRecipientAge;
    _selectedInterests = widget.initialInterests;

    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    // 1. جلب المنتجات
    await _fetchProducts();
    await _loadCartData();

    // 2. جلب الويش لست الخاصة بالمستخدم
    final wishResult = await ApiService.getWishlists();

    if (wishResult['success'] && wishResult['data'].isNotEmpty) {
      final myWishlist = wishResult['data'][0];
      _myWishlistId = myWishlist['id'];

      if (myWishlist['products'] != null) {
        _wishlistedProductIds = (myWishlist['products'] as List)
            .map((p) => p['id'] as int)
            .toList();
      }
    } else {
      // إنشاء ويش لست إذا ما عنده
      final createResult = await ApiService.createWishlist('My Wishlist');

      if (createResult['success']) {
        _myWishlistId = createResult['data']['id'];
      }
    }
  }

  // 🔄 جلب المنتجات مع البحث والفلاتر والتصنيف
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    final prodResult = await ApiService.getProducts(
      search: _searchController.text.trim(),
      category: _selectedCategory,
      occasion: _apiOccasionValue(_selectedOccasion),
      targetGender: _apiGenderValue(_selectedGender),
      recipientAge: _selectedRecipientAge,
      interests: _selectedInterests,
      budgetMin: _minBudgetController.text.trim(),
      budgetMax: _maxBudgetController.text.trim(),
    );

    if (mounted) {
      setState(() {
        if (prodResult['success']) {
          _products = prodResult['products'];
        }
        _isLoading = false;
      });
    }
  }
  Future<void> _loadCartData() async {
  final items = await ApiService.getCartItems();

  if (mounted) {
    setState(() {
      _cartItems = items;
    });
  }
}

int _getCartItemsCount() {
  int count = 0;

  for (final item in _cartItems) {
    count += (item['quantity'] ?? 1) as int;
  }

  return count;
}

double _calculateCartTotal() {
  double total = 0;

  for (final item in _cartItems) {
    final price = double.tryParse(item['price'].toString()) ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    total += price * quantity;
  }

  return total;
}

  Future<void> _toggleWishlist(int productId) async {
    if (_myWishlistId == null) return;

    final isAlreadyWishlisted = _wishlistedProductIds.contains(productId);

    setState(() {
      if (isAlreadyWishlisted) {
        _wishlistedProductIds.remove(productId);
      } else {
        _wishlistedProductIds.add(productId);
      }
    });

    Map<String, dynamic> result;

    if (isAlreadyWishlisted) {
      result = await ApiService.removeFromWishlist(productId, _myWishlistId!);
    } else {
      result = await ApiService.addToWishlist(productId, _myWishlistId!);
    }

    if (!result['success']) {
      setState(() {
        if (isAlreadyWishlisted) {
          _wishlistedProductIds.add(productId);
        } else {
          _wishlistedProductIds.remove(productId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error updating wishlist'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAlreadyWishlisted
                ? 'Removed from Wishlist'
                : 'Added to Wishlist',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // 🎛️ واجهة الفلاتر
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Products 🎛️',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedOccasion = null;
                            _selectedGender = null;
                            _selectedRecipientAge = null;
                            _selectedInterests = null;
                            _minBudgetController.clear();
                            _maxBudgetController.clear();
                          });
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // فلتر المناسبة
                  const Text(
                    'Occasion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _occasions.map((occ) {
                      final isSelected = _selectedOccasion == occ;

                      return ChoiceChip(
                        label: Text(occ),
                        selected: isSelected,
                        selectedColor:
                            const Color(0xFFA35CFF).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFA35CFF)
                              : Colors.black,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedOccasion = selected ? occ : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // فلتر الجنس
                  const Text(
                    'For Whom?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _genders.map((gen) {
                      final isSelected = _selectedGender == gen;

                      return ChoiceChip(
                        label: Text(gen),
                        selected: isSelected,
                        selectedColor:
                            const Color(0xFF53B175).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF53B175)
                              : Colors.black,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedGender = selected ? gen : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // فلتر الميزانية
                  const Text(
                    'Budget (SAR)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minBudgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min',
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxBudgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max',
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedRecipientAge != null ||
                      _selectedInterests != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Home filters: ${_activeFiltersText()}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // زر تطبيق الفلاتر
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchProducts();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648DDB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
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
            );
          },
        );
      },
    );
  }

  // 🧩 شريط التصنيفات
  Widget _buildCategorySection() {
    return Container(
      color: Colors.white,
      height: 78,
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final String categoryName = category['name'];

          final bool isSelected = categoryName == 'All'
              ? _selectedCategory == null
              : _selectedCategory == categoryName;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory =
                    categoryName == 'All' ? null : categoryName;
              });

              _fetchProducts();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFA35CFF)
                    : const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFA35CFF)
                      : const Color(0xFFE6E6E6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    category['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildCartSummaryBar() {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CartPage(),
            ),
          );

          _loadCartData();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF53B175),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                '${_getCartItemsCount()} item${_getCartItemsCount() == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${_calculateCartTotal().toStringAsFixed(0)} SAR',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'View Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _clearAllFiltersAndSearch() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedOccasion = null;
      _selectedGender = null;
      _selectedRecipientAge = null;
      _selectedInterests = null;
      _minBudgetController.clear();
      _maxBudgetController.clear();
    });

    _fetchProducts();
  }
  


  Widget _buildActiveFiltersBanner() {
    if (_activeFiltersText().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFA35CFF).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFA35CFF).withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.filter_alt_outlined,
              color: Color(0xFFA35CFF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _activeFiltersText(),
                style: const TextStyle(
                  color: Color(0xFFA35CFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            GestureDetector(
              onTap: _clearAllFiltersAndSearch,
              child: const Icon(
                Icons.close,
                color: Color(0xFFA35CFF),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      bottomNavigationBar:
      _cartItems.isEmpty ? null : _buildCartSummaryBar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.initialTitle ?? 'Market',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyWishlistPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          // 🔍 شريط البحث وزر الفلتر
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) => _fetchProducts(),
                    decoration: InputDecoration(
                      hintText: 'Search for gifts...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _fetchProducts();
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // زر الفلاتر
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA35CFF),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA35CFF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildActiveFiltersBanner(),

          // 🧩 التصنيفات
          _buildCategorySection(),

          // 🛍️ شبكة المنتجات
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF648DDB),
                    ),
                  )
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No products found.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _clearAllFiltersAndSearch,
                              child: const Text(
                                'Clear Filters & Search',
                                style: TextStyle(
                                  color: Color(0xFF648DDB),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isWishlisted =
                              _wishlistedProductIds.contains(product['id']);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // صورة المنتج مع زر المفضلة
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              product['image_url'] ??
                                                  'https://via.placeholder.com/150',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _toggleWishlist(product['id']),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isWishlisted
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isWishlisted
                                                  ? Colors.redAccent
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // تفاصيل المنتج وزر الإضافة
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? 'Product Name',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'SAR ${product['price']}',
                                        style: const TextStyle(
                                          color: Color(0xFF648DDB),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await ApiService.addToCart(
                                              product
                                                  as Map<String, dynamic>,
                                            );
                                            await _loadCartData();

                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${product['name']} added to cart!',
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFF53B175),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  action: SnackBarAction(
                                                    label: 'View',
                                                    textColor: Colors.white,
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const CartPage(),
                                                        ),
                                                      );
                                                      _loadCartData();
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF648DDB),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'Add to Cart',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
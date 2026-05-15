import 'package:flutter/material.dart';
import 'api_service.dart';
import 'contact_selection_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'market_page.dart';
import 'account_page.dart';
import 'edit_profile_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);

    final items = await ApiService.getCartItems();

    if (!mounted) return;

    setState(() {
      cartItems = items;
      _isLoading = false;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MarketPage(),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _selectedIndex = 1);
        }
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AccountPage(),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _selectedIndex = 1);
        }
      });
    }
  }

  Future<void> _incrementQuantity(int index) async {
    int newQty = (cartItems[index]['quantity'] ?? 1) + 1;
    setState(() {
      cartItems[index]['quantity'] = newQty;
    });
    await ApiService.updateCartQuantity(cartItems[index]['id'], newQty);
  }

  Future<void> _decrementQuantity(int index) async {
    if ((cartItems[index]['quantity'] ?? 1) > 1) {
      int newQty = cartItems[index]['quantity'] - 1;
      setState(() {
        cartItems[index]['quantity'] = newQty;
      });
      await ApiService.updateCartQuantity(cartItems[index]['id'], newQty);
    }
  }

  Future<void> _removeItem(int index) async {
    int productId = cartItems[index]['id'];
    setState(() {
      cartItems.removeAt(index);
    });
    await ApiService.removeFromCart(productId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      double price = double.tryParse(item['price'].toString()) ?? 0.0;
      int qty = item['quantity'] ?? 1;
      total += (price * qty);
    }
    return total;
  }

  void _createGroupGift() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cartItems.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Group Gift currently supports one product only. Please keep one item in the cart.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final product = cartItems.first;
    final int productId = product['id'];
    final String productName = product['name'] ?? 'Product';

    _showCreateQattahDialog(productId, productName);
  }

 Future<void> _showCreateQattahDialog(int productId, String productName) async {
  final pageContext = context;

  final localData = await ApiService.getUserData();

  final titleController = TextEditingController();
  final paymentNoteController = TextEditingController();

  final bankNameController = TextEditingController(
    text: localData?['bank_name']?.toString() ?? '',
  );
  final ibanController = TextEditingController(
    text: localData?['iban']?.toString() ?? '',
  );
  final accountHolderController = TextEditingController(
    text: localData?['account_holder_name']?.toString() ?? '',
  );

  String cleanIban(String value) {
    return value.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
  }

  bool isValidSaudiIban(String value) {
    final cleaned = cleanIban(value);
    return RegExp(r'^SA\d{22}$').hasMatch(cleaned);
  }

  showDialog(
    context: pageContext,
    builder: (dialogContext) {
      bool isCreating = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Create Qattah',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected gift: $productName'),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Qattah Title (Optional)',
                      hintText: 'e.g. Birthday Gift for Ali',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: paymentNoteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Payment Note (Optional)',
                      hintText: 'e.g. Transfer after pledging',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Banking Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Required so participants know where to transfer.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'e.g. Al Rajhi',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: ibanController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'IBAN',
                      hintText: 'SA3915000999103143430001',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: accountHolderController,
                    decoration: InputDecoration(
                      labelText: 'Account Holder Name',
                      hintText: 'e.g. Hisham Khalid',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isCreating ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA35CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isCreating
                    ? null
                    : () async {
                        final bankName = bankNameController.text.trim();
                        final iban = cleanIban(ibanController.text.trim());
                        final accountHolder =
                            accountHolderController.text.trim();

                        if (bankName.isEmpty ||
                            iban.isEmpty ||
                            accountHolder.isEmpty) {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete your banking information.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        if (!isValidSaudiIban(iban)) {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invalid Saudi IBAN. It must start with SA and contain 24 characters.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final title = titleController.text.trim().isNotEmpty
                            ? titleController.text.trim()
                            : 'Qattah for $productName';

                        setDialogState(() => isCreating = true);

                        final bankResult = await ApiService.updateBankingInfo(
                          bankName: bankName,
                          iban: iban,
                          accountHolderName: accountHolder,
                        );

                        if (!mounted) return;

                        if (bankResult['success'] != true) {
                          setDialogState(() => isCreating = false);

                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                bankResult['message'] ??
                                    'Failed to update banking information',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final result = await ApiService.createQattah(
                          title,
                          productId,
                          paymentMethodNote:
                              paymentNoteController.text.trim(),
                        );

                        if (!mounted) return;

                        setDialogState(() => isCreating = false);
                        Navigator.pop(dialogContext);

                        if (result['success']) {
                          final newQattah = result['data'];
                          final String inviteCode =
                              newQattah['invite_code'].toString();

                          _showQattahCreatedDialog(inviteCode, title);

                          await ApiService.clearCart();

                          setState(() {
                            cartItems.clear();
                          });
                        } else {
                          final message =
                              result['message'] ?? 'Failed to create Qattah';

                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}
  void _showBankInfoRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Banking Information Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You need to complete your banking information before creating a Qattah.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA35CFF),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
              child: const Text(
                'Complete Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showQattahCreatedDialog(String inviteCode, String qattahTitle) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Group Gift Created! 🎉',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA35CFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFA35CFF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      color: Color(0xFFA35CFF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code: $inviteCode',
                      style: const TextStyle(
                        color: Color(0xFFA35CFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Would you like to invite friends from your contacts?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA35CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.people,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Invite Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactSelectionPage(
                      inviteCode: inviteCode,
                      qattahTitle: qattahTitle,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

 Future<void> _openAffiliateLink(String? link) async {
  if (link == null || link.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No store link available for this product.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final uri = Uri.tryParse(link.trim());

  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid store link.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open store link.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open store link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _buyFromStore() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // إذا فيه منتج واحد فقط، افتح رابطه مباشرة
    if (cartItems.length == 1) {
      _openAffiliateLink(cartItems.first['affiliate_link']?.toString());
      return;
    }

    // إذا فيه أكثر من منتج، خل المستخدم يختار أي منتج يفتح رابطه
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Choose a product',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: cartItems.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['name'] ?? 'Product'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _openAffiliateLink(item['affiliate_link']?.toString());
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartItems.isEmpty
                ? _buildEmptyCart()
                : Column(
                    children: [
                      _buildHeader(),
                      Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 11),
                          color: const Color(0xFFE2E2E2)),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(25),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            return _buildCartItem(index);
                          },
                        ),
                      ),
                      _buildBottomSection(),
                    ],
                  ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('Your cart is empty',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Text('Add some products to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // يرجع للهوم عشان يروح الماركت
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse Products',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'My Cart',
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700),
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
          Container(
            width: 73,
            height: 88,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image_url'] ??
                    'https://via.placeholder.com/150', // ✅ تعديل الاسم ليتوافق مع الباكند
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Product',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Reddit Sans',
                            fontWeight: FontWeight.w600,
                            height: 1.1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          size: 18, color: Colors.grey.shade600),
                      onPressed: () => _removeItem(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item['description'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF7C7C7C),
                      fontSize: 12,
                      fontFamily: 'Reddit Sans',
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E2E2)),
                          borderRadius: BorderRadius.circular(17)),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _decrementQuantity(index),
                            child: Container(
                                width: 35,
                                height: 35,
                                alignment: Alignment.center,
                                child: const Icon(Icons.remove,
                                    size: 18, color: Color(0xFF7C7C7C))),
                          ),
                          Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            child: Text('${item['quantity'] ?? 1}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Reddit Sans',
                                    fontWeight: FontWeight.w600)),
                          ),
                          GestureDetector(
                            onTap: () => _incrementQuantity(index),
                            child: Container(
                                width: 35,
                                height: 35,
                                alignment: Alignment.center,
                                child: const Icon(Icons.add,
                                    size: 18, color: Color(0xFF53B175))),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${((double.tryParse(item['price'].toString()) ?? 0.0) * (item['quantity'] ?? 1)).toStringAsFixed(0)} SAR',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Reddit Sans',
                          fontWeight: FontWeight.w600),
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
              offset: const Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 67,
            child: ElevatedButton(
              onPressed: _buyFromStore,
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
                  const Text(
                    'Buy from Store',
                    style: TextStyle(
                      color: Color(0xFFFCFCFC),
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF489E67),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_calculateTotal().toStringAsFixed(0)} SAR',
                      style: const TextStyle(
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
          SizedBox(
            width: double.infinity,
            height: 67,
            child: ElevatedButton(
              onPressed: _createGroupGift,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA35CFF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19)),
                  elevation: 0),
              child: const Text('Create Group Gift',
                  style: TextStyle(
                      color: Color(0xFFFCFCFC),
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBottomNavigationBar() {
  return SafeArea(
    minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
    child: Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.shopping_cart_rounded, 'Cart'),
          _buildNavItem(2, Icons.storefront_rounded, 'Market'),
          _buildNavItem(3, Icons.person_rounded, 'Account'),
        ],
      ),
    ),
  );
}

Widget _buildNavItem(int index, IconData icon, String label) {
  final bool isSelected = _selectedIndex == index;

  return GestureDetector(
    onTap: () => _onNavItemTapped(index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 14 : 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFA35CFF).withOpacity(0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFFA35CFF)
                : const Color(0xFF7C7C7C),
            size: 23,
          ),
          if (isSelected) ...[
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFA35CFF),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}